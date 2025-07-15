package io.github.tonyblack10.chatwebflux.service;

import io.github.tonyblack10.chatwebflux.util.DocumentProcessorUtil;
import java.util.List;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.http.codec.multipart.FilePart;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

@Service
public class RagService {

  private static final org.slf4j.Logger LOGGER = org.slf4j.LoggerFactory.getLogger(
      RagService.class);

  private final VectorStore vectorStore;
  private final DocumentProcessorUtil documentProcessorUtil;

  public RagService(VectorStore vectorStore, DocumentProcessorUtil documentProcessorUtil) {
    this.vectorStore = vectorStore;
    this.documentProcessorUtil = documentProcessorUtil;
  }

  public Mono<Void> processDocuments(Flux<FilePart> files) {
    return documentProcessorUtil.processDocuments(files)
        .flatMap(this::saveToVectorStore)
        .then();
  }

  public Mono<List<Document>> saveToVectorStore(List<Document> documents) {
    return Mono.fromCallable(() -> {
      LOGGER.info("Writing {} documents to vector store.", documents.size());
      vectorStore.accept(documents);
      LOGGER.info("{} documents have been written to vector store.", documents.size());
      return documents;
    }).subscribeOn(Schedulers.boundedElastic());
  }
}
