package io.github.tonyblack10.chatwebflux;

import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;

@Service
public class RagService {

  private final VectorStore vectorStore;

  public RagService(VectorStore vectorStore) {
    this.vectorStore = vectorStore;
  }
}
