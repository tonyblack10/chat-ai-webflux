<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chat SDK Demo</title>
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="/styles.css">
    <!-- HTMX -->
    <script src="https://unpkg.com/htmx.org@1.9.6"></script>
</head>

<body>
<div class="container-fluid h-100">
    <div class="row h-100">
        <!-- Sidebar -->
        <div class="col-md-3 sidebar">
            <div class="sidebar-header">
                <h3>Chat SDK</h3>
                <div class="d-flex align-items-center">
                    <button class="btn btn-sm btn-primary me-2">New Chat</button>
                </div>
            </div>
            <div class="chat-list">
                <div class="chat-item active" data-chat-id="1" hx-get="/api/chats/1" hx-target="#chat-messages"
                     hx-trigger="click">
                    <div class="chat-item-content">
                        <h6>Welcome Chat</h6>
                    </div>
                    <div class="chat-item-time">2m ago</div>
                </div>
            </div>
        </div>

        <!-- Sidebar Overlay -->
        <div class="sidebar-overlay" id="sidebar-overlay" onclick="closeSidebar()"></div>

        <!-- Main Chat Area -->
        <div class="col-md-9 main-chat">
            <div class="chat-header">
                <div class="d-flex align-items-center">
                    <button class="btn btn-outline-secondary btn-sm me-2 d-md-none" id="sidebar-toggle"
                            onclick="toggleSidebar()">
                        <i class="bi bi-list"></i>
                    </button>
                    <div>
                        <h5>Welcome Chat</h5>
                    </div>
                </div>
                <div class="chat-header-actions">
                    <button class="btn btn-outline-secondary btn-sm" id="theme-toggle" onclick="toggleTheme()">
                        <i class="bi bi-moon-fill" id="theme-icon"></i>
                        <span class="ms-1 d-none d-md-inline">Dark Mode</span>
                    </button>
                </div>
            </div>
            <div class="chat-body" id="chat-messages">
                <!-- System message -->
                <div class="message system-message">
                    <div class="message-content">
                        <p>Welcome to Chat SDK Demo! This is a demonstration of our chat interface.</p>
                    </div>
                </div>

                <!-- Received message -->
                <div class="message received">
                    <div class="message-content">
                        <div class="message-header">
                            <strong>Chat Assistant</strong>
                            <small>10:30 AM</small>
                        </div>
                        <p>Hello! How can I help you today?</p>
                    </div>
                </div>

                <!-- Sent message -->
                <div class="message sent">
                    <div class="message-content">
                        <div class="message-header">
                            <small>10:32 AM</small>
                            <strong>You</strong>
                        </div>
                        <p>I'd like to know more about integrating the Chat SDK into my application.</p>
                    </div>
                </div>

                <!-- Received message with multiple paragraphs -->
                <div class="message received">
                    <div class="message-content">
                        <div class="message-header">
                            <strong>Chat Assistant</strong>
                            <small>10:33 AM</small>
                        </div>
                        <p>Sure! Our Chat SDK is designed to be easy to integrate into any application.</p>
                        <p>You can start by installing the package via npm: <code>npm install chat-sdk</code></p>
                        <p>Would you like to see some code examples?</p>
                    </div>
                </div>
            </div>

            <div class="chat-footer">
                <form id="chat-form" hx-post="/ask" hx-target="#chat-messages" hx-swap="beforeend" hx-indicator="#spinner"
                      class="message-form">
                    <div class="input-group">
                        <label for="file-input" class="btn btn-outline-secondary">
                            <i class="bi bi-paperclip"></i>
                        </label>
                        <input type="file" id="file-input" name="file" class="d-none">
                        <input type="text" class="form-control" placeholder="Type a message..." id="message-input"
                               name="content" required>
                        <button class="btn btn-primary" type="submit">
                            <i class="bi bi-send"></i>
                            <span class="htmx-indicator" id="spinner">
                                <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                            </span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Bootstrap JavaScript -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<!-- Custom JavaScript for handling chat interactions -->
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Ensure form submission also adds user message to the chat
        const chatForm = document.getElementById('chat-form');
        chatForm.addEventListener('htmx:beforeRequest', function(event) {
            const messageInput = document.getElementById('message-input');
            const messageContent = messageInput.value.trim();

            if (messageContent) {
                // Add user message to chat
                const userMessage = createUserMessageHTML(messageContent);
                document.getElementById('chat-messages').insertAdjacentHTML('beforeend', userMessage);

                // Clear input after sending
                setTimeout(() => {
                    messageInput.value = '';
                }, 100);
            }
        });
    });

    function createUserMessageHTML(content) {
        const now = new Date();
        const time = now.getHours().toString().padStart(2, '0') + ':' +
                    now.getMinutes().toString().padStart(2, '0');

        return (
            '<div class="message sent">' +
                '<div class="message-content">' +
                    '<div class="message-header">' +
                        '<small>' + time + '</small>' +
                        '<strong>You</strong>' +
                    '</div>' +
                    '<p>' + content + '</p>' +
                '</div>' +
            '</div>'
        );
    }

    function toggleSidebar() {
        document.querySelector('.sidebar').classList.toggle('active');
        document.querySelector('.sidebar-overlay').classList.toggle('active');
    }

    function closeSidebar() {
        document.querySelector('.sidebar').classList.remove('active');
        document.querySelector('.sidebar-overlay').classList.remove('active');
    }

    function toggleTheme() {
        document.body.classList.toggle('dark-theme');
        const themeIcon = document.getElementById('theme-icon');
        if (document.body.classList.contains('dark-theme')) {
            themeIcon.classList.replace('bi-moon-fill', 'bi-sun-fill');
        } else {
            themeIcon.classList.replace('bi-sun-fill', 'bi-moon-fill');
        }
    }
</script>
</body>

</html>