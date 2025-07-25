@template.layout.main(content = @`
    <!-- Container principal do chat -->
    <div class="chat-container d-flex flex-column vh-100">
        <!-- Cabeçalho com botão nova conversa -->
        <div class="chat-header d-flex justify-content-between align-items-center mb-3">
            <h2 class="mb-0 fw-bold">Chat AI</h2>
            <button id="new-chat" class="btn btn-primary d-flex align-items-center gap-2"
                   hx-post="/chat/new"
                   hx-target="#chat-messages"
                   hx-indicator="#loading-indicator"
                   hx-swap="innerHTML">
                <i class="bi bi-plus-lg"></i>
                Nova Conversa
            </button>
        </div>

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

        /* Efeito de digitação para o cursor */
        .cursor {
            display: inline-block;
            width: 0.5em;
            height: 1em;
            background: var(--bs-primary);
            margin-left: 2px;
            animation: cursor-blink 1s infinite;
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

        @keyframes cursor-blink {
            0%, 100% { opacity: 1; }
            50% { opacity: 0; }
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
        document.addEventListener('DOMContentLoaded', function() {
            const textarea = document.getElementById('message-input');
            const chatMessages = document.getElementById('chat-messages');
            const chatForm = document.getElementById('chat-form');

            // Função para ajustar altura do textarea
            function adjustTextareaHeight() {
                textarea.style.height = 'auto';
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
            const observer = new MutationObserver(mutations => {
                scrollToBottom();

                // Inicializar efeitos de digitação para novas mensagens da IA
                mutations.forEach(mutation => {
                    if (mutation.type === 'childList') {
                        mutation.addedNodes.forEach(node => {
                            if (node.nodeType === Node.ELEMENT_NODE) {
                                const typingElements = node.querySelectorAll('.typing-effect');
                                typingElements.forEach(element => {
                                    initTypingEffect(element);
                                });
                            }
                        });
                    }
                });
            });

            observer.observe(chatMessages, {
                childList: true,
                subtree: true
            });

            // Modificar envio do formulário para renderização local da mensagem do usuário
            chatForm.addEventListener('submit', function(event) {
                // Não interromper o fluxo do HTMX
                // event.preventDefault();

                const message = textarea.value.trim();
                if (message) {
                    // Renderizar mensagem do usuário localmente
                    addUserMessage(message);
                }
            });

            // Função para adicionar mensagem do usuário
            function addUserMessage(message) {
                const userMessageHTML =
                    '<div class="message user-message">' +
                        '<div class="message-avatar">' +
                            '<i class="bi bi-person-fill"></i>' +
                        '</div>' +
                        '<div class="message-content">' +
                            '<div class="message-text">' +
                                '<p>' + escapeHTML(message) + '</p>' +
                            '</div>' +
                        '</div>' +
                    '</div>';

                chatMessages.insertAdjacentHTML('beforeend', userMessageHTML);
                scrollToBottom();
            }

            // Função para escapar HTML e evitar XSS
            function escapeHTML(text) {
                const div = document.createElement('div');
                div.textContent = text;
                return div.innerHTML;
            }

            // Efeito de digitação para as mensagens da IA
            function initTypingEffect(element) {
                if (!element || element.getAttribute('data-typing-started') === 'true') return;

                element.setAttribute('data-typing-started', 'true');
                const fullText = element.getAttribute('data-full-text');
                if (!fullText) return;

                const typingSpeed = 20; // velocidade de digitação (ms)
                let i = 0;

                element.innerHTML = ''; // Limpar o conteúdo
                const cursor = document.createElement('span');
                cursor.className = 'cursor';
                element.appendChild(cursor);

                const typeCharacter = () => {
                    if (i < fullText.length) {
                        // Inserir antes do cursor
                        cursor.insertAdjacentHTML('beforebegin', fullText.charAt(i));
                        i++;

                        // Aceleração do efeito de digitação para textos longos
                        const speed = fullText.length > 500 ?
                            (i > 100 ? typingSpeed/4 : typingSpeed/2) :
                            typingSpeed;

                        setTimeout(typeCharacter, speed);
                    } else {
                        // Quando terminar, usar o HTML completo para garantir formatação correta
                        element.innerHTML = fullText;
                    }
                };

                setTimeout(typeCharacter, 300); // Pequeno atraso para iniciar a digitação
            }

            // Limpar o campo após envio do formulário
            chatForm.addEventListener('htmx:afterOnLoad', function() {
                textarea.value = '';
                textarea.style.height = 'auto';
                textarea.focus();
            });

            // Inicializar scroll
            scrollToBottom();

            // Inicializar efeitos de digitação existentes
            document.querySelectorAll('.typing-effect').forEach(initTypingEffect);
        });
    </script>
`)
