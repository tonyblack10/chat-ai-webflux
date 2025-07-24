@template.layout.main(content = @`
    <!-- Container principal do chat -->
    <div class="chat-container d-flex flex-column vh-100">

        <!-- Indicador de carregamento -->
        <div id="loading-indicator" class="htmx-indicator d-flex justify-content-center my-2">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Carregando...</span>
            </div>
        </div>

        <!-- Container de mensagens com scroll -->
        <div id="chat-container" class="chat-messages-container flex-grow-1 overflow-auto mb-4">
            <div id="chat-messages" class="chat-messages pb-3">
                <!-- Mensagem inicial do sistema -->
                <div class="message ai-message">
                    <div class="message-avatar">
                        <i class="bi bi-robot"></i>
                    </div>
                    <div class="message-content">
                        <div class="message-text markdown-content">
                            <p>Olá! Como posso ajudar você hoje?</p>
                        </div>
                    </div>
                </div>

                <!-- Mensagem de exemplo do usuário -->
                <div class="message user-message">
                    <div class="message-avatar">
                        <i class="bi bi-person-fill"></i>
                    </div>
                    <div class="message-content">
                        <div class="message-text">
                            <p>Quais são as melhores práticas para desenvolvimento web com Spring Boot e WebFlux?</p>
                        </div>
                    </div>
                </div>

                <!-- Mensagem de exemplo da IA com formatação markdown -->
                <div class="message ai-message">
                    <div class="message-avatar">
                        <i class="bi bi-robot"></i>
                    </div>
                    <div class="message-content">
                        <div class="message-text markdown-content">
                            <p>Aqui estão algumas melhores práticas para desenvolvimento com Spring Boot e WebFlux:</p>
                            <ol>
                                <li><strong>Use programação reativa de ponta a ponta</strong> - Não misture código bloqueante com não-bloqueante</li>
                                <li><strong>Utilize o tipo Mono para respostas únicas</strong> e <strong>Flux para streams de dados</strong></li>
                                <li><strong>Evite bloqueios</strong> - Nunca chame <code>block()</code>, <code>blockFirst()</code> ou <code>blockLast()</code> em produção</li>
                            </ol>
                            <p>Exemplo de um controlador WebFlux:</p>
                            <pre><code>@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;

    // Constructor injection
    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/{id}")
    </code></pre>
                            <p>Lembre-se que WebFlux é mais útil para aplicações com muitas conexões concorrentes ou operações de I/O assíncronas.</p>
                        </div>
                    </div>
                </div>
                <!-- As mensagens serão inseridas aqui via HTMX -->
            </div>
        </div>

        <!-- Área de digitação de mensagem -->
        <div class="chat-input-container mt-auto mb-3">
            <form id="chat-form" class="d-flex gap-2"
                  hx-post="/chat/send"
                  hx-target="#chat-messages"
                  hx-indicator="#typing-indicator"
                  hx-swap="beforeend">
                <div class="input-group">
                    <textarea name="message" id="message-input"
                              class="form-control"
                              placeholder="Digite sua mensagem..."
                              rows="1"
                              required
                              aria-label="Mensagem"
                              autofocus></textarea>
                    <button type="submit" class="btn btn-primary d-flex align-items-center">
                        <i class="bi bi-send-fill"></i>
                        <span class="d-none d-md-inline ms-2">Enviar</span>
                    </button>
                </div>
            </form>
            <!-- Indicador de digitação -->
            <div id="typing-indicator" class="typing-indicator htmx-indicator mt-2">
                <span>IA está digitando<span class="dot-typing">...</span></span>
            </div>
        </div>
    </div>

    <style>
        /* Estilos do chat */
        .chat-container {
            margin-top: -20px; /* Compensar o margin do layout */
            height: calc(100vh - 80px);
        }

        .chat-messages-container {
            border-radius: 8px;
            background-color: rgba(0,0,0,0.03);
            border: 1px solid rgba(0,0,0,0.1);
        }

        .message {
            display: flex;
            margin: 16px;
            padding: 8px;
            border-radius: 8px;
            animation: fadeIn 0.3s ease-in-out;
        }

        .user-message {
            flex-direction: row-reverse;
            background-color: rgba(13, 110, 253, 0.1);
            margin-left: 64px;
        }

        .ai-message {
            background-color: rgba(255, 255, 255, 0.7);
            margin-right: 64px;
        }

        [data-bs-theme="dark"] .ai-message {
            background-color: rgba(255, 255, 255, 0.1);
        }

        .message-avatar {
            width: 38px;
            height: 38px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.2rem;
            margin: 0 8px;
        }

        .user-message .message-avatar {
            background-color: var(--bs-primary);
            color: white;
        }

        .ai-message .message-avatar {
            background-color: var(--bs-secondary);
            color: white;
        }

        .message-content {
            flex: 1;
            max-width: 90%;
        }

        .message-text {
            padding: 8px 12px;
            border-radius: 8px;
        }

        /* Estilos para Markdown */
        .markdown-content pre {
            background-color: rgba(0,0,0,0.05);
            padding: 10px;
            border-radius: 6px;
            overflow-x: auto;
        }

        [data-bs-theme="dark"] .markdown-content pre {
            background-color: rgba(255,255,255,0.1);
        }

        .markdown-content code {
            font-family: monospace;
            padding: 2px 4px;
            background-color: rgba(0,0,0,0.05);
            border-radius: 4px;
        }

        [data-bs-theme="dark"] .markdown-content code {
            background-color: rgba(255,255,255,0.1);
        }

        /* Indicador de digitação */
        .typing-indicator {
            color: var(--bs-secondary);
            font-size: 0.9rem;
            font-style: italic;
            margin-left: 10px;
        }

        .dot-typing {
            display: inline-block;
            animation: dotTyping 1.5s infinite;
        }

        /* Tornar o textarea autoexpansível */
        #message-input {
            resize: none;
            overflow: hidden;
            min-height: 38px;
            max-height: 150px;
            transition: height 0.2s ease;
        }

        /* Animações */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @keyframes dotTyping {
            0% { content: ''; }
            25% { content: '.'; }
            50% { content: '..'; }
            75% { content: '...'; }
            100% { content: ''; }
        }

        /* Responsividade */
        @media (max-width: 768px) {
            .chat-container {
                height: calc(100vh - 70px);
            }

            .message {
                margin: 10px;
            }

            .user-message {
                margin-left: 32px;
            }

            .ai-message {
                margin-right: 32px;
            }
        }
    </style>

    <script>
        // Script para autoexpansão do textarea
        document.addEventListener('DOMContentLoaded', function() {
            const textarea = document.getElementById('message-input');

            // Função para ajustar altura do textarea
            function adjustTextareaHeight() {
                // Reset height to auto para calcular tamanho correto
                textarea.style.height = 'auto';
                // Set height para o scroll height para expandir conforme conteúdo
                textarea.style.height = (textarea.scrollHeight) + 'px';
            }

            // Eventos para ajustar altura
            textarea.addEventListener('input', adjustTextareaHeight);
            textarea.addEventListener('focus', adjustTextareaHeight);

            // Função para scroll automático para novas mensagens
            function scrollToBottom() {
                const chatContainer = document.getElementById('chat-container');
                chatContainer.scrollTop = chatContainer.scrollHeight;
            }

            // Observador para detectar novas mensagens e rolar
            const observer = new MutationObserver(scrollToBottom);
            const chatMessages = document.getElementById('chat-messages');

            observer.observe(chatMessages, {
                childList: true,
                subtree: true
            });

            // Limpar o campo após envio do formulário
            document.getElementById('chat-form').addEventListener('htmx:afterOnLoad', function() {
                textarea.value = '';
                textarea.style.height = 'auto';
                textarea.focus();
            });

            // Carregar histórico ao iniciar (se existir)
            document.body.addEventListener('htmx:load', function() {
                scrollToBottom();
            });

            // Inicializar scroll
            scrollToBottom();
        });
    </script>
`)

