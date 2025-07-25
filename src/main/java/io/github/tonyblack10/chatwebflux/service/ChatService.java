package io.github.tonyblack10.chatwebflux.service;

import static org.springframework.ai.chat.memory.ChatMemory.CONVERSATION_ID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.client.advisor.vectorstore.QuestionAnswerAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

@Service
public class ChatService {

  private static final Logger logger = LoggerFactory.getLogger(ChatService.class);

  private final ChatClient chatClient;

  public ChatService(ChatClient.Builder chatClientBuilder, VectorStore vectorStore,
      ChatMemory chatMemory, ToolCallbackProvider tools) {
    var questionAnswerAdvisor = QuestionAnswerAdvisor.builder(vectorStore)
        .searchRequest(SearchRequest.builder().build())
        .build();

    var chatMemoryAdvisor = MessageChatMemoryAdvisor.builder(chatMemory).build();

    this.chatClient = chatClientBuilder
        .defaultAdvisors(chatMemoryAdvisor, questionAnswerAdvisor)
        .defaultToolCallbacks(tools)
        .build();
  }

  public Flux<String> askQuestion(String question, String conversationId) {
    logger.info("askQuestion called with question: {}, conversationId: {}", question, conversationId);

    return this.chatClient.prompt()
        .system("Retorne o conteudo da pergunta no formato markdown.")
        .user(question)
        .advisors(advisorSpec -> advisorSpec
            .param(CONVERSATION_ID, conversationId)
        )
        .stream()
        .content();
  }

}
