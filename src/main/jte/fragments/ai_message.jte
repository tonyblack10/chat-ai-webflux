@param String response

<!-- Mensagem da IA com formatação markdown -->
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
        <div class="message-text markdown-content typing-effect" data-full-text="${response}">
            <!-- O conteúdo será preenchido via JavaScript com efeito de digitação -->
        </div>
    </div>
</div>
