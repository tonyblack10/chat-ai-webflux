package io.github.tonyblack10.chatwebflux;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

@RestController
public class ChatController {

  private final ChatService chatService;

  public ChatController(ChatService chatService) {
    this.chatService = chatService;
  }

  @GetMapping("/ask")
  public Flux<Answer> ask(@RequestParam String question) {
    return chatService.askQuestion(question)
        .map(Answer::new);
  }
}
