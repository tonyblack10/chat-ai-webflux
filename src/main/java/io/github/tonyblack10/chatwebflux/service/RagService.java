package io.github.tonyblack10.chatwebflux.service;

import io.github.tonyblack10.chatwebflux.util.DocumentProcessorUtil;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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

  public Flux<Map<String, String>> processDocuments(Flux<FilePart> files) {
    return documentProcessorUtil.processDocuments(files)
        .flatMap(this::saveToVectorStore)
        .flatMapIterable(documents -> documents)
        .map(this::documentToFileInfo);
  }

  private Map<String, String> documentToFileInfo(Document document) {
    LOGGER.info("Processing document: {}", document);

    Map<String, String> fileInfo = new HashMap<>();
    Map<String, Object> metadata = document.getMetadata();

    // Obter informações básicas do documento
    fileInfo.put("name", metadata.getOrDefault("filename", "Documento sem nome").toString());
    fileInfo.put("size", metadata.getOrDefault("size", "0").toString());
    fileInfo.put("status", "Processado");

    // Adicionar timestamp atual formatado
    LocalDateTime now = LocalDateTime.now();
    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
    fileInfo.put("timestamp", now.format(formatter));

    return fileInfo;
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
