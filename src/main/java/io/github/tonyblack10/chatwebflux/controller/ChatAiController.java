package io.github.tonyblack10.chatwebflux.controller;

import io.github.tonyblack10.chatwebflux.dto.QuestionDTO;
import io.github.tonyblack10.chatwebflux.service.ChatService;
import io.github.tonyblack10.chatwebflux.util.TemplateRenderer;
import java.util.HashMap;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
public class ChatAiController {

  private final TemplateRenderer templateRenderer;
  private final ChatService chatService;

  public ChatAiController(TemplateRenderer templateRenderer, ChatService chatService) {
    this.templateRenderer = templateRenderer;
    this.chatService = chatService;
  }

  @PostMapping(value = "/chat/send", produces = MediaType.TEXT_HTML_VALUE)
  public Mono<String> chat(QuestionDTO question, @RequestHeader("x-conversation-id") String conversationId) {
    System.out.println("Received question: " + question.message());

    // Usar o chatService para processar a mensagem de forma reativa
    return chatService.askQuestion(question.message(), conversationId)
        .collectList()
        .map(chunks -> String.join("", chunks))
        .flatMap(aiResponse -> {
          Map<String, Object> model = new HashMap<>();
          model.put("response", aiResponse);
          return templateRenderer.render("fragments/ai_message.jte", model);
        });
  }

  @PostMapping(value = "/chat/new", produces = MediaType.TEXT_HTML_VALUE)
  public Mono<String> newChat() {
    // Limpar o histórico de chat e retornar mensagem inicial
    return templateRenderer.render("fragments/ai_message.jte", "response", "<p>Olá! Como posso ajudar você hoje?</p>");
  }

  /**
   * Método para gerar uma resposta da IA com base na pergunta.
   * Em um ambiente real, isso se conectaria ao seu serviço de IA.
   */
  private String generateAiResponse(String message) {
    // Exemplo de resposta para demonstração
    if (message.toLowerCase().contains("webflux")) {
      return "<p>Sobre Spring WebFlux, aqui estão algumas informações importantes:</p>" +
          "<ul>" +
          "<li><strong>Programação reativa</strong> - WebFlux usa Reactor para programação reativa</li>" +
          "<li><strong>Non-blocking</strong> - Todas as operações são não bloqueantes</li>" +
          "<li><strong>Escalabilidade</strong> - Ideal para aplicações com alto throughput</li>" +
          "</ul>" +
          "<p>Exemplo de código WebFlux:</p>" +
          "<pre><code>@GetMapping(\"/items\")\n" +
          "public Flux&lt;Item&gt; getAllItems() {\n" +
          "    return itemRepository.findAll();\n" +
          "}</code></pre>";
    } else {
      return "<p>Entendi sua mensagem. Em que mais posso ajudar?</p>";
    }
  }
}
