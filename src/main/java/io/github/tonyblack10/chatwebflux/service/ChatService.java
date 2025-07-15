package io.github.tonyblack10.chatwebflux.service;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.client.advisor.vectorstore.QuestionAnswerAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

@Service
public class ChatService {

  private final ChatClient chatClient;

  public ChatService(ChatClient.Builder chatClientBuilder, VectorStore vectorStore, ChatMemory chatMemory) {
    var questionAnswerAdvisor = QuestionAnswerAdvisor.builder(vectorStore)
        .searchRequest(SearchRequest.builder().build())
        .build();

    var chatMemoryAdvisor = MessageChatMemoryAdvisor.builder(chatMemory).build();

    this.chatClient = chatClientBuilder
        .defaultAdvisors(chatMemoryAdvisor, questionAnswerAdvisor)
        .build();
  }

  public Flux<String> askQuestion(String question) {
    return this.chatClient.prompt()
        .user(question)
        .stream()
        .content();
  }

}
