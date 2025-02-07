/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package software.amazon.smithy.model.loader;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Map;
import java.util.function.Consumer;
import java.util.function.Supplier;
import java.util.logging.Logger;
import software.amazon.smithy.model.SourceException;
import software.amazon.smithy.model.SourceLocation;
import software.amazon.smithy.model.node.Node;
import software.amazon.smithy.model.node.ObjectNode;
import software.amazon.smithy.model.node.StringNode;
import software.amazon.smithy.model.traits.TraitFactory;
import software.amazon.smithy.utils.IoUtils;

/**
 * Used to load Smithy models from .json, .smithy, and .jar files.
 */
final class ModelLoader {

    private static final Logger LOGGER = Logger.getLogger(ModelLoader.class.getName());

    private ModelLoader() {}

    /**
     * Parses models and pushes {@link LoadOperation}s to the given consumer.
     *
     * <p>The format contained in the supplied {@code InputStream} is
     * determined based on the file extension in the provided
     * {@code filename}.
     *
     * @param traitFactory Factory used to create traits.
     * @param properties Bag of loading properties.
     * @param filename Filename to assign to the model.
     * @param operationConsumer Where loader operations are published.
     * @param contentSupplier The supplier that provides an InputStream. The
     *   supplied {@code InputStream} is automatically closed when the loader
     *   has finished reading from it.
     * @throws SourceException if there is an error reading from the contents.
     */
    static void load(
            TraitFactory traitFactory,
            Map<String, Object> properties,
            String filename,
            Consumer<LoadOperation> operationConsumer,
            Supplier<InputStream> contentSupplier
    ) {
        try (InputStream inputStream = contentSupplier.get()) {
            if (filename.endsWith(".smithy")) {
                String contents = IoUtils.toUtf8String(inputStream);
                new IdlModelParser(filename, contents).parse(operationConsumer);
            } else if (filename.endsWith(".jar")) {
                loadJar(traitFactory, properties, filename, operationConsumer);
            } else if (filename.endsWith(".json") || filename.equals(SourceLocation.NONE.getFilename())) {
                // Assume it's JSON if there's a N/A filename.
                loadParsedNode(Node.parse(inputStream, filename), operationConsumer);
            } else {
                LOGGER.warning(() -> "No ModelLoader was able to load " + filename);
            }
        } catch (IOException e) {
            throw new ModelImportException("Error loading " + filename + ": " + e.getMessage(), e);
        }
    }

    // Loads all supported JSON formats. Each JSON format is expected to have
    // a top-level version property that contains a string. This version
    // is then used to delegate loading to different versions of the
    // Smithy JSON AST format.
    //
    // This loader supports version 1.0 and 2.0. Support for 0.5 and 0.4 was removed in 0.10.
    static void loadParsedNode(Node node, Consumer<LoadOperation> operationConsumer) {
        ObjectNode model = node.expectObjectNode("Smithy documents must be an object. Found {type}.");
        StringNode versionNode = model.expectStringMember("smithy");
        Version version = Version.fromString(versionNode.getValue());

        if (version != null) {
            new AstModelLoader(version, model).parse(operationConsumer);
        } else {
            throw new ModelSyntaxException("Unsupported Smithy version number: " + versionNode.getValue(), versionNode);
        }
    }

    // Allows importing JAR files by discovering models inside of a JAR file.
    // This is similar to model discovery, but done using an explicit import.
    private static void loadJar(
            TraitFactory traitFactory,
            Map<String, Object> properties,
            String filename,
            Consumer<LoadOperation> operationConsumer
    ) {
        URL manifestUrl = ModelDiscovery.createSmithyJarManifestUrl(filename);
        LOGGER.fine(() -> "Loading Smithy model imports from JAR: " + manifestUrl);

        for (URL model : ModelDiscovery.findModels(manifestUrl)) {
            try {
                URLConnection connection = model.openConnection();

                if (properties.containsKey(ModelAssembler.DISABLE_JAR_CACHE)) {
                    connection.setUseCaches(false);
                }

                load(traitFactory, properties, model.toExternalForm(), operationConsumer, () -> {
                    try {
                        return connection.getInputStream();
                    } catch (IOException e) {
                        throw throwIoJarException(model, e);
                    }
                });
            } catch (IOException e) {
                throw throwIoJarException(model, e);
            }
        }
    }

    private static ModelImportException throwIoJarException(URL model, Throwable e) {
        return new ModelImportException(
                String.format("Error loading Smithy model from URL `%s`: %s", model, e.getMessage()), e);
    }
}
