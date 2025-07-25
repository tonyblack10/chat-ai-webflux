package io.github.tonyblack10.chatwebflux.controller;

import io.github.tonyblack10.chatwebflux.dto.Answer;
import io.github.tonyblack10.chatwebflux.dto.QuestionDTO;
import io.github.tonyblack10.chatwebflux.service.ChatService;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

@RestController
public class ChatController {

  private final ChatService chatService;
  private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

  public ChatController(ChatService chatService) {
    this.chatService = chatService;
  }

  @PostMapping("/ask")
  public Flux<String> ask(QuestionDTO question) {
    return chatService.askQuestion(question.message())
        .map(this::createAssistantMessageHtml);
  }

  // Endpoint alternativo para API JSON se necessário
  @PostMapping(value = "/api/ask", produces = MediaType.APPLICATION_JSON_VALUE)
  public Flux<Answer> apiAsk(@RequestBody QuestionDTO question) {
    return chatService.askQuestion(question.message())
        .map(Answer::new);
  }

  private String createAssistantMessageHtml(String content) {
    String currentTime = LocalTime.now().format(TIME_FORMATTER);
    return """
        <div class="message received">
            <div class="message-content">
                <div class="message-header">
                    <strong>Chat Assistant</strong>
                    <small>%s</small>
                </div>
                <p>%s</p>
            </div>
        </div>
        """.formatted(currentTime, content);
  }
}
