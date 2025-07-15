package io.github.tonyblack10.chatwebflux.service;

import java.util.List;
import java.util.function.Consumer;
import java.util.function.Function;
import org.springframework.ai.document.Document;
import org.springframework.ai.reader.tika.TikaDocumentReader;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.messaging.Message;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

@Service
public class RagService {

  private static final org.slf4j.Logger LOGGER = org.slf4j.LoggerFactory.getLogger(RagService.class);

  private final VectorStore vectorStore;

  public RagService(VectorStore vectorStore) {
    this.vectorStore = vectorStore;
  }

  public VectorStore getVectorStore() {
    return vectorStore;
  }

  public Function<Flux<Message<byte[]>>, Flux<List<Document>>> documentReader() {
    return resourceFlux -> resourceFlux
        .map(message ->
            new TikaDocumentReader(new ByteArrayResource(message.getPayload()))
                .get()
                .stream()
                .peek(document -> {
                  document.getMetadata()
                      .put("source", message.getHeaders().get("file_name"));
                })
                .toList()
        );
  }

  public Function<Flux<List<Document>>, Flux<List<Document>>> splitter() {
    return documentListFlux ->
        documentListFlux
            .map(unsplitList -> new TokenTextSplitter().apply(unsplitList));
  }

  public Consumer<Flux<List<Document>>> vectorStoreConsumer(VectorStore vectorStore) {
    return documentFlux -> documentFlux
        .doOnNext(documents -> {
          LOGGER.info("Writing {} documents to vector store.", documents.size());
          vectorStore.accept(documents);
          LOGGER.info("{} documents have been written to vector store.", documents.size());
        })
        .subscribe();
  }
}
