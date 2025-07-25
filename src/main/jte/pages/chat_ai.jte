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
                        <div class="message-header d-flex justify-content-between align-items-center">
                            <span class="message-timestamp text-muted small">
                                ${java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss").format(java.time.LocalDateTime.now())}
                            </span>
                            <button class="btn btn-sm btn-link copy-btn" title="Copiar mensagem">
                                <i class="bi bi-clipboard"></i>
                            </button>
                        </div>
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
                  hx-swap="beforeend"
                  hx-headers='{"x-conversation-id": ""}'> <!-- O valor será preenchido via JS -->
                <div class="input-group">
                    <textarea name="message" id="message-input"
                              class="form-control"
                              placeholder="Digite sua mensagem..."
                              rows="1"
                              required
                              aria-label="Mensagem"
                              autofocus></textarea>
                    <button type="submit" class="btn btn-primary d-flex align-items-center" id="send-button">
                        <i class="bi bi-send-fill"></i>
                        <span class="d-none d-md-inline ms-2">Enviar</span>
                    </button>
                </div>
            </form>
            <!-- Indicador de digitação -->
            <div id="typing-indicator" class="typing-indicator htmx-indicator mt-2">
                <span>IA está pensando<span class="dot-typing">...</span></span>
            </div>
        </div>
    </div>

    <!-- Incluir marked.js para processamento de Markdown -->
    <script src="https://cdn.jsdelivr.net/npm/marked@4.3.0/marked.min.js"></script>

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

        /* Estilos para o cabeçalho da mensagem com timestamp e botão de cópia */
        .message-header {
            padding: 0 12px 4px;
            border-bottom: 1px solid rgba(0,0,0,0.05);
            margin-bottom: 6px;
        }

        [data-bs-theme="dark"] .message-header {
            border-bottom-color: rgba(255,255,255,0.1);
        }

        .copy-btn {
            padding: 0 4px;
            color: var(--bs-secondary);
            transition: color 0.2s;
        }

        .copy-btn:hover {
            color: var(--bs-primary);
        }

        /* Feedback de cópia */
        .copy-feedback {
            position: absolute;
            background: var(--bs-success);
            color: white;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.8rem;
            opacity: 0;
            transform: translateY(-10px);
            transition: opacity 0.3s, transform 0.3s;
            z-index: 100;
        }

        .copy-feedback.show {
            opacity: 1;
            transform: translateY(0);
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
            const sendButton = document.getElementById('send-button');

            // Gerar um UUID para o conversationId
            const conversationId = generateUUID();
            console.log("Conversation ID: ", conversationId);

            // Definir o header com o conversationId para todas as requisições HTMX
            chatForm.setAttribute('hx-headers', JSON.stringify({
                "x-conversation-id": conversationId
            }));

            // Função para gerar UUID v4
            function generateUUID() {
                return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                    const r = Math.random() * 16 | 0,
                        v = c === 'x' ? r : (r & 0x3 | 0x8);
                    return v.toString(16);
                });
            }

            // Configurar marked para segurança e estilização
            marked.setOptions({
                breaks: true,           // Quebras de linha como no GitHub
                sanitize: false,        // Não sanitizar (vamos fazer isso manualmente)
                smartLists: true,       // Listas mais inteligentes
                smartypants: true,      // Tipografia melhorada
                highlight: function(code, lang) {
                    return code; // Poderia implementar highlight.js aqui
                }
            });

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

            // Adicionar handler para tecla Enter
            textarea.addEventListener('keydown', function(event) {
                if (event.key === 'Enter' && !event.shiftKey) {
                    event.preventDefault(); // Impede a quebra de linha

                    const message = textarea.value.trim();
                    if (message) {
                        // Simular clique no botão enviar
                        sendButton.click();
                    }
                }
            });

            // Modificar envio do formulário para renderização local da mensagem do usuário
            chatForm.addEventListener('htmx:before-request', function(event) {
                const message = textarea.value.trim();

                // Verificar se a mensagem está vazia
                if (!message) {
                    event.preventDefault();
                    return;
                }

                // Renderizar mensagem do usuário localmente
                addUserMessage(message);

                // Limpar o campo imediatamente
                textarea.value = '';
                adjustTextareaHeight();

                // Desabilitar campos durante o processamento
                textarea.disabled = true;
                sendButton.disabled = true;
            });

            // Função para adicionar mensagem do usuário
            function addUserMessage(message) {
                const currentTime = new Date();
                const formattedTime = formatDateTime(currentTime);

                const userMessageHTML =
                    '<div class="message user-message">' +
                        '<div class="message-avatar">' +
                            '<i class="bi bi-person-fill"></i>' +
                        '</div>' +
                        '<div class="message-content">' +
                            '<div class="message-header d-flex justify-content-between align-items-center">' +
                                '<span class="message-timestamp text-muted small">' + formattedTime + '</span>' +
                                '<button class="btn btn-sm btn-link copy-btn" title="Copiar mensagem">' +
                                    '<i class="bi bi-clipboard"></i>' +
                                '</button>' +
                            '</div>' +
                            '<div class="message-text">' +
                                '<p>' + escapeHTML(message) + '</p>' +
                            '</div>' +
                        '</div>' +
                    '</div>';

                chatMessages.insertAdjacentHTML('beforeend', userMessageHTML);
                scrollToBottom();

                // Adicionar event listener para o botão de cópia
                const copyButtons = chatMessages.querySelectorAll('.copy-btn');
                const lastCopyButton = copyButtons[copyButtons.length - 1];
                if (lastCopyButton) {
                    lastCopyButton.addEventListener('click', handleCopyClick);
                }
            }

            // Formatar data e hora no padrão solicitado
            function formatDateTime(date) {
                const day = String(date.getDate()).padStart(2, '0');
                const month = String(date.getMonth() + 1).padStart(2, '0');
                const year = date.getFullYear();
                const hours = String(date.getHours()).padStart(2, '0');
                const minutes = String(date.getMinutes()).padStart(2, '0');
                const seconds = String(date.getSeconds()).padStart(2, '0');

                return day + '/' + month + '/' + year + ' ' + hours + ':' + minutes + ':' + seconds;
            }

            // Handler para o clique no botão de cópia
            function handleCopyClick(event) {
                // Encontrar o conteúdo da mensagem
                const messageContent = event.target.closest('.message-content');
                const messageText = messageContent.querySelector('.message-text');

                // Extrair o texto sem formatação
                const textToCopy = messageText.textContent || messageText.innerText;

                // Copiar para a área de transferência
                navigator.clipboard.writeText(textToCopy.trim())
                    .then(() => showCopyFeedback(event.target.closest('.copy-btn')))
                    .catch(err => console.error('Erro ao copiar texto: ', err));
            }

            // Mostrar feedback visual da cópia
            function showCopyFeedback(button) {
                // Criar elemento de feedback
                const feedback = document.createElement('span');
                feedback.className = 'copy-feedback';
                feedback.textContent = 'Copiado!';

                // Posicionar próximo ao botão
                button.appendChild(feedback);

                // Mostrar feedback
                setTimeout(() => feedback.classList.add('show'), 10);

                // Remover feedback após 2 segundos
                setTimeout(() => {
                    feedback.classList.remove('show');
                    setTimeout(() => feedback.remove(), 300);
                }, 2000);
            }

            // Adicionar event listeners para os botões de cópia existentes
            document.querySelectorAll('.copy-btn').forEach(button => {
                button.addEventListener('click', handleCopyClick);
            });

            // Função para renderizar markdown de forma segura
            function renderMarkdown(text) {
                try {
                    return marked.parse(text);
                } catch (e) {
                    console.error('Erro ao renderizar markdown:', e);
                    return text;
                }
            }

            // Efeito de digitação para as mensagens da IA - VERSÃO CORRIGIDA
            function initTypingEffect(element) {
                if (!element || element.getAttribute('data-typing-started') === 'true') return;

                element.setAttribute('data-typing-started', 'true');
                const rawText = element.getAttribute('data-full-text');
                if (!rawText) return;

                // Criar um elemento temporário para armazenar o HTML renderizado
                const tempContainer = document.createElement('div');
                // Renderizar o markdown para HTML
                tempContainer.innerHTML = renderMarkdown(rawText);

                // Extrair apenas o texto visível (sem as tags HTML)
                const textContent = tempContainer.textContent || tempContainer.innerText || '';

                // Configuração do efeito de digitação
                const typingSpeed = 15; // velocidade de digitação (ms)
                let charIndex = 0;

                // Limpar o conteúdo do elemento original
                element.innerHTML = '';

                // Criar o cursor de digitação
                const cursor = document.createElement('span');
                cursor.className = 'cursor';
                element.appendChild(cursor);

                // Função para revelar o texto gradualmente
                const typeNextChar = () => {
                    if (charIndex < textContent.length) {
                        // Calcular a porcentagem concluída
                        const percentComplete = charIndex / textContent.length;

                        // Gerar HTML parcial com base na porcentagem
                        // Isso preserva todas as tags HTML enquanto revela apenas parte do texto
                        const visibleLength = Math.floor(percentComplete * rawText.length);

                        // Renderizar o markdown parcial
                        const partialHtml = renderMarkdown(rawText.substring(0, visibleLength) + '█');

                        // Substituir o último caractere (█) pelo cursor
                        const htmlWithoutLastChar = partialHtml.substring(0, partialHtml.lastIndexOf('█'));
                        element.innerHTML = htmlWithoutLastChar;
                        element.appendChild(cursor);

                        // Avançar para o próximo caractere
                        charIndex++;

                        // Aceleração para textos longos
                        let speed = typingSpeed;
                        if (textContent.length > 500) {
                            if (charIndex > 100) speed = typingSpeed / 4;
                            else speed = typingSpeed / 2;
                        }

                        setTimeout(typeNextChar, speed);
                    } else {
                        // Quando terminar, usar o HTML completo para garantir formatação correta
                        element.innerHTML = renderMarkdown(rawText);
                    }
                };

                // Iniciar o efeito de digitação após um pequeno atraso
                setTimeout(typeNextChar, 300);
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

            // Manipuladores de eventos HTMX para controle de estado
            document.body.addEventListener('htmx:beforeRequest', function(e) {
                if (e.detail.elt.id === 'chat-form') {
                    // Desabilitar campos durante a requisição
                    textarea.disabled = true;
                    sendButton.disabled = true;
                }
            });

            document.body.addEventListener('htmx:afterOnLoad', function(e) {
                // Reabilitar campos após a resposta
                textarea.disabled = false;
                sendButton.disabled = false;

                // Ajustar foco
                textarea.focus();
            });

            document.body.addEventListener('htmx:responseError', function(e) {
                // Reabilitar campos em caso de erro
                textarea.disabled = false;
                sendButton.disabled = false;

                // Exibir mensagem de erro
                console.error('Erro na comunicação com o servidor', e.detail);
                alert('Ocorreu um erro ao enviar sua mensagem. Por favor, tente novamente.');
            });
        });

        // Escuta para função escapeHTML se ela não existir
        function escapeHTML(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
    </script>
`)
