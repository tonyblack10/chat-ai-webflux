@param gg.jte.Content content
@param String activeTab = "chat"

<!doctype html>
<html lang="pt-BR" data-bs-theme="light">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>RAG System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-LN+7fdVzj6u52u30Kp6M/trliBMCMKTyK833zpbD+pXdCLuTusPj697FH4R/5mcr" crossorigin="anonymous">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    <script src="https://unpkg.com/htmx.org@1.9.6"></script>
    <style>
        body {
            min-height: 100vh;
            transition: background-color 0.3s, color 0.3s;
        }
        .navbar {
            box-shadow: 0 2px 4px rgba(0,0,0,.1);
        }
        .theme-icon {
            font-size: 1.25rem;
            cursor: pointer;
        }
        .nav-link.active {
            font-weight: bold;
        }
        .page-content {
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <div class="container">
            <a class="navbar-brand" href="/">CHAT AI</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarMain" aria-controls="navbarMain" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarMain">
                <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                    <li class="nav-item">
                        <a class="nav-link ${activeTab.equals("chat") ? "active" : ""}" href="/">Chat</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link ${activeTab.equals("upload") ? "active" : ""}" href="/rag/upload">Upload de Documentos</a>
                    </li>
                </ul>
                <div class="d-flex">
                    <div class="theme-toggle" id="themeToggle">
                        <i class="bi bi-sun-fill theme-icon" id="lightThemeIcon"></i>
                        <i class="bi bi-moon-fill theme-icon" id="darkThemeIcon" style="display: none;"></i>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <div class="container page-content">
        ${content}
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/js/bootstrap.bundle.min.js" integrity="sha384-ndDqU0Gzau9qJ1lfW4pNLlhNTkCfHzAVBReH9diLvGRem5+R9g2FzA8ZGN954O5Q" crossorigin="anonymous"></script>

    <script src="/js/theme.js"></script>
</body>
</html>