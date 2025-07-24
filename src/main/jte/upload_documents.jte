@import io.github.tonyblack10.chatwebflux.controller.RagController

@param RagController ragController

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload de Documentos - RAG System</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://unpkg.com/htmx.org@1.9.9"></script>
    <style>
        body {
            background-color: #f8f9fa;
            min-height: 100vh;
        }
        .upload-container {
            max-width: 800px;
            margin: 0 auto;
            background-color: #fff;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
            padding: 30px;
            margin-top: 50px;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .file-list {
            margin-top: 20px;
            max-height: 300px;
            overflow-y: auto;
        }
        .file-item {
            padding: 10px;
            background-color: #f8f9fa;
            margin-bottom: 10px;
            border-radius: 5px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .progress {
            margin-top: 20px;
            margin-bottom: 20px;
            height: 20px;
        }
        .upload-message {
            margin-top: 20px;
            padding: 15px;
            border-radius: 5px;
        }
        .success-message {
            background-color: #d4edda;
            color: #155724;
        }
        .error-message {
            background-color: #f8d7da;
            color: #721c24;
        }
        #dropArea {
            border: 2px dashed #007bff;
            border-radius: 8px;
            padding: 50px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        #dropArea:hover, #dropArea.drag-over {
            background-color: #e9f5ff;
            border-color: #0056b3;
        }
        .nav-link {
            color: #495057;
        }
        .nav-link.active {
            font-weight: bold;
            color: #007bff;
        }
    </style>
</head>
<body>
    <div class="container mt-4">

        <div class="upload-container">
            <div class="header">
                <h1>Upload de Documentos</h1>
                <p>Faça upload dos seus documentos para utilizar no sistema RAG</p>
            </div>

            <div
                id="dropArea"
                onclick="document.getElementById('fileInput').click()">
                <h4>Arraste e solte arquivos aqui ou clique para selecionar</h4>
                <p>Tamanho máximo total: 20MB</p>
            </div>

            <form id="uploadForm"
                  hx-encoding="multipart/form-data"
                  hx-post="/rag/upload"
                  hx-trigger="submit"
                  hx-indicator="#progressContainer"
                  hx-target="#uploadResponse">

                <input type="file" id="fileInput" name="files" multiple style="display: none"
                       onchange="updateFileList()">

                <div class="d-flex justify-content-between mt-3">
                    <span id="totalSize">Tamanho total: 0 KB</span>
                    <button type="button" class="btn btn-secondary" onclick="clearFiles()">Limpar</button>
                </div>

                <div class="file-list mt-4" id="fileList">
                    <p>Nenhum arquivo selecionado</p>
                </div>

                <div class="progress mt-4 mb-4" id="progressContainer">
                    <div class="progress-bar progress-bar-striped progress-bar-animated"
                         id="uploadProgress"
                         role="progressbar"
                         aria-valuenow="0"
                         aria-valuemin="0"
                         aria-valuemax="100"
                         style="width: 0%">0%</div>
                </div>

                <div class="d-grid gap-2 mt-4">
                    <button class="btn btn-primary" type="submit" id="uploadButton" disabled>
                        Processar Documentos
                    </button>
                </div>

                <div id="uploadResponse" class="mt-4"></div>
            </form>
        </div>
    </div>

    <script>
        const dropArea = document.getElementById('dropArea');
        const fileInput = document.getElementById('fileInput');
        const fileList = document.getElementById('fileList');
        const totalSizeElement = document.getElementById('totalSize');
        const uploadButton = document.getElementById('uploadButton');
        const progressBar = document.getElementById('uploadProgress');
        const MAX_SIZE = 20 * 1024 * 1024; // 20MB em bytes

        // Eventos para arrastar e soltar
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            dropArea.addEventListener(eventName, preventDefaults, false);
        });

        function preventDefaults(e) {
            e.preventDefault();
            e.stopPropagation();
        }

        ['dragenter', 'dragover'].forEach(eventName => {
            dropArea.addEventListener(eventName, highlight, false);
        });

        ['dragleave', 'drop'].forEach(eventName => {
            dropArea.addEventListener(eventName, unhighlight, false);
        });

        function highlight() {
            dropArea.classList.add('drag-over');
        }

        function unhighlight() {
            dropArea.classList.remove('drag-over');
        }

        dropArea.addEventListener('drop', handleDrop, false);

        function handleDrop(e) {
            const dt = e.dataTransfer;
            const files = dt.files;
            fileInput.files = files;
            updateFileList();
        }

        function updateFileList() {
            const files = fileInput.files;
            let totalSize = 0;

            if (files.length > 0) {
                let fileListHTML = '';
                for (const file of files) {
                    totalSize += file.size;
                    fileListHTML += '<div class="file-item">' +
                        '<div>' +
                        '<strong>' + file.name + '</strong>' +
                        '<span class="text-secondary ms-2">' + formatFileSize(file.size) + '</span>' +
                        '</div>' +
                        '<span class="badge bg-primary">' + getFileType(file) + '</span>' +
                        '</div>';
                }
                fileList.innerHTML = fileListHTML;

                if (totalSize > MAX_SIZE) {
                    totalSizeElement.innerHTML = '<span class="text-danger">Tamanho total excedido: ' + formatFileSize(totalSize) + ' / 20MB</span>';
                    uploadButton.disabled = true;
                } else {
                    totalSizeElement.innerHTML = 'Tamanho total: ' + formatFileSize(totalSize);
                    uploadButton.disabled = false;
                }
            } else {
                fileList.innerHTML = '<p>Nenhum arquivo selecionado</p>';
                totalSizeElement.innerHTML = 'Tamanho total: 0 KB';
                uploadButton.disabled = true;
            }
        }

        function clearFiles() {
            fileInput.value = '';
            fileList.innerHTML = '<p>Nenhum arquivo selecionado</p>';
            totalSizeElement.innerHTML = 'Tamanho total: 0 KB';
            uploadButton.disabled = true;

            // Limpar mensagem de resposta
            const uploadResponse = document.getElementById('uploadResponse');
            if (uploadResponse) {
                uploadResponse.innerHTML = '';
            }

            // Resetar barra de progresso
            progressBar.style.width = '0%';
            progressBar.textContent = '0%';
        }

        function formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        function getFileType(file) {
            const extension = file.name.split('.').pop().toLowerCase();
            const docTypes = ['doc', 'docx'];
            const pdfTypes = ['pdf'];
            const txtTypes = ['txt', 'md', 'rtf'];
            const imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

            if (docTypes.includes(extension)) return 'DOC';
            if (pdfTypes.includes(extension)) return 'PDF';
            if (txtTypes.includes(extension)) return 'TXT';
            if (imageTypes.includes(extension)) return 'IMG';
            return extension.toUpperCase();
        }

        // Configurar eventos HTMX para controle de progresso
        document.addEventListener('htmx:xhr:loadstart', function() {
            // Mostrar o contêiner de progresso antes do envio
            const progressContainer = document.getElementById('progressContainer');
            progressContainer.style.display = 'block';
            progressBar.style.width = '0%';
            progressBar.textContent = '0%';
        });

        document.addEventListener('htmx:xhr:progress', function(evt) {
            // Verificar se evt.detail e evt.detail.xhr existem antes de acessar propriedades
            if (evt.detail && evt.detail.loaded && evt.detail.total) {
                const percent = Math.round((evt.detail.loaded / evt.detail.total) * 100);
                progressBar.style.width = percent + '%';
                progressBar.textContent = percent + '%';
            }
        });

        document.addEventListener('htmx:beforeSend', function(evt) {
            // Configurar o upload para relatar progresso
            if (evt.detail && evt.detail.xhr) {
                evt.detail.xhr.upload.onprogress = function(e) {
                    if (e.lengthComputable) {
                        const percent = Math.round((e.loaded / e.total) * 100);
                        progressBar.style.width = percent + '%';
                        progressBar.textContent = percent + '%';
                    }
                };
            }
        });

        document.addEventListener('htmx:afterRequest', function(evt) {
            // Esconder o contêiner de progresso após o término da requisição
            document.getElementById('progressContainer').style.display = 'none';

            if (evt.detail.xhr.status === 200) {
                const response = evt.detail.xhr.responseText;
                document.getElementById('uploadResponse').innerHTML =
                    '<div class="upload-message success-message">' + response + '</div>';
            } else {
                const response = evt.detail.xhr.responseText || "Erro ao processar documentos";
                document.getElementById('uploadResponse').innerHTML =
                    '<div class="upload-message error-message">' + response + '</div>';
            }
        });

        // Inicialmente ocultar o contêiner de progresso
        document.getElementById('progressContainer').style.display = 'none';
    </script>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
