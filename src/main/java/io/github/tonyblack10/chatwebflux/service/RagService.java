package io.github.tonyblack10.chatwebflux.service;

import io.github.tonyblack10.chatwebflux.util.DocumentProcessorUtil;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
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
  private final ReactiveRedisTemplate<String, Map<String, String>> redisTemplate;

  public RagService(VectorStore vectorStore,
                   DocumentProcessorUtil documentProcessorUtil,
                   ReactiveRedisTemplate<String, Map<String, String>> redisTemplate) {
    this.vectorStore = vectorStore;
    this.documentProcessorUtil = documentProcessorUtil;
    this.redisTemplate = redisTemplate;
  }

  public Flux<Map<String, String>> processDocuments(Flux<FilePart> files) {
    return documentProcessorUtil.processDocuments(files)
        .flatMap(this::saveToVectorStore)
        .flatMapIterable(documents -> documents)
        .map(this::documentToFileInfo)
        .flatMap(this::saveToRedis);
  }

  /**
   * Recupera o histórico de documentos armazenados no Redis
   * @return Um Flux com as informações dos documentos armazenados
   */
  public Flux<Map<String, String>> getUploadHistory() {
    return redisTemplate.keys("doc:*")
        .flatMap(key -> redisTemplate.opsForValue().get(key)
            .map(info -> {
                info.put("name", key.substring(4)); // Remover prefixo "doc:"
                return info;
            }));
  }

  /**
   * Remove um documento do histórico no Redis
   * @param fileName Nome do arquivo a ser removido
   * @return Mono<Boolean> indicando sucesso ou falha
   */
  public Mono<Boolean> deleteDocument(String fileName) {
    return redisTemplate.delete("doc:" + fileName)
        .map(r -> r > 0);
  }

  private Mono<Map<String, String>> saveToRedis(Map<String, String> fileInfo) {
    String fileName = fileInfo.get("name");
    // Criamos uma cópia para não modificar o original que será retornado ao cliente
    Map<String, String> redisInfo = new HashMap<>(fileInfo);

    // Prefixar a chave com "doc:" para facilitar buscas futuras
    return redisTemplate.opsForValue().set("doc:" + fileName, redisInfo)
        .thenReturn(fileInfo); // Retorna o objeto original (sem modificações)
  }

  private Map<String, String> documentToFileInfo(Document document) {
    Map<String, String> fileInfo = new HashMap<>();
    Map<String, Object> metadata = document.getMetadata();

    // Obter informações básicas do documento
    fileInfo.put("name", metadata.getOrDefault("filename", "Documento sem nome").toString());
    fileInfo.put("size", metadata.getOrDefault("size", "0").toString());
    fileInfo.put("status", "Processado");
    fileInfo.put("id", document.getId());

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
