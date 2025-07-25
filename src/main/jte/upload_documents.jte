@template.layout.main(activeTab = "upload", content = @`
    <div class="container mt-4">
        <div class="card shadow-sm">
            <div class="card-header bg-primary text-white">
                <h2 class="mb-0">Upload de Documentos</h2>
            </div>

            <div class="card-body">
                <div class="mb-4">
                    <p class="text-muted">Faça upload dos seus documentos para processamento e indexação no sistema de RAG.</p>
                    <ul class="text-muted small">
                        <li>Formatos aceitos: PDF, DOC, DOCX, TXT, CSV</li>
                        <li>Tamanho máximo: 20MB no total</li>
                        <li>Você pode enviar múltiplos arquivos simultaneamente</li>
                    </ul>
                </div>

                <!-- Área de mensagens -->
                <div id="message-area"></div>

                <!-- Área de upload com drag & drop -->
                <div id="drop-area" class="border border-2 border-dashed rounded-3 p-5 text-center mb-3">
                    <div class="py-3">
                        <i class="bi bi-cloud-upload fs-1 text-primary mb-2"></i>
                        <h4>Arraste e solte arquivos aqui</h4>
                        <p class="text-muted">ou</p>
                        <button type="button" id="select-files-btn" class="btn btn-outline-primary">
                            <i class="bi bi-folder"></i> Selecionar Arquivos
                        </button>
                    </div>
                </div>

                <!-- Formulário oculto para upload -->
                <form id="upload-form"
                      hx-encoding="multipart/form-data"
                      hx-post="/rag/upload"
                      hx-target="#result-container"
                      hx-indicator="#progress-indicator"
                      hx-trigger="submit"
                      hx-on::after-request="resetForm()"
                      class="d-none">
                    <input type="file" id="file-input" name="files" multiple
                           accept=".pdf,.doc,.docx,.txt,.csv">
                    <button type="submit" id="upload-btn">Enviar</button>
                </form>

                <!-- Lista de arquivos selecionados -->
                <div id="file-list-container" class="d-none mb-3">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center bg-light">
                            <h5 class="mb-0">Arquivos selecionados</h5>
                            <span id="total-size-badge" class="badge bg-info">0 KB</span>
                        </div>
                        <div class="table-responsive">
                            <table class="table table-hover mb-0">
                                <thead>
                                    <tr>
                                        <th>Nome</th>
                                        <th>Tipo</th>
                                        <th>Tamanho</th>
                                        <th>Status</th>
                                        <th>Ações</th>
                                    </tr>
                                </thead>
                                <tbody id="file-list">
                                    <!-- Arquivos serão adicionados via JavaScript -->
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Botões de ação -->
                <div class="d-flex justify-content-end gap-2">
                    <button id="clear-btn" class="btn btn-outline-secondary d-none">
                        <i class="bi bi-x-circle"></i> Limpar
                    </button>
                    <button id="submit-btn" class="btn btn-primary d-none">
                        <i class="bi bi-upload"></i> Fazer Upload
                    </button>
                </div>

                <!-- Área de progresso -->
                <div id="progress-indicator" class="htmx-indicator mt-3">
                    <div class="progress" style="height: 25px;">
                        <div class="progress-bar progress-bar-striped progress-bar-animated"
                             role="progressbar"
                             aria-valuenow="0"
                             aria-valuemin="0"
                             aria-valuemax="100"
                             style="width: 0%">
                            <span id="progress-text">0%</span>
                        </div>
                    </div>
                    <p class="text-center mt-2">
                        <small class="text-muted">Processando arquivos, por favor aguarde...</small>
                    </p>
                </div>

                <!-- Resultados do upload -->
                <div id="result-container" class="mt-3"></div>

                <!-- Histórico de uploads (placeholder) -->
                <div id="upload-history" class="mt-4">
                    <h5>Histórico de Uploads</h5>
                    <div class="table-responsive">
                        <table class="table table-striped table-hover">
                            <thead>
                                <tr>
                                    <th>Nome do Arquivo</th>
                                    <th>Tamanho</th>
                                    <th>Data do Upload</th>
                                    <th>Status</th>
                                    <th>Ações</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td colspan="5" class="text-center text-muted">Nenhum arquivo processado</td>
                                </tr>
                                <!-- Os arquivos processados serão adicionados aqui pelo servidor -->
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Configuração inicial e constantes
        const MAX_SIZE_MB = 20;
        const MAX_SIZE_BYTES = MAX_SIZE_MB * 1024 * 1024;
        const VALID_EXTENSIONS = ['.pdf', '.doc', '.docx', '.txt', '.csv'];

        // Elementos DOM
        const dropArea = document.getElementById('drop-area');
        const fileInput = document.getElementById('file-input');
        const fileList = document.getElementById('file-list');
        const fileListContainer = document.getElementById('file-list-container');
        const totalSizeBadge = document.getElementById('total-size-badge');
        const selectFilesBtn = document.getElementById('select-files-btn');
        const submitBtn = document.getElementById('submit-btn');
        const clearBtn = document.getElementById('clear-btn');
        const uploadForm = document.getElementById('upload-form');
        const messageArea = document.getElementById('message-area');
        const uploadHistoryTable = document.querySelector('#upload-history table tbody');

        // Variáveis de estado
        let selectedFiles = [];
        let totalSize = 0;

        // Gerenciamento de arquivos
        function updateFileList() {
            // Limpar lista existente
            fileList.innerHTML = '';

            // Populando a tabela com os arquivos
            if (selectedFiles.length > 0) {
                fileListContainer.classList.remove('d-none');
                submitBtn.classList.remove('d-none');
                clearBtn.classList.remove('d-none');

                selectedFiles.forEach((file, index) => {
                    const row = document.createElement('tr');

                    // Nome do arquivo
                    const nameCell = document.createElement('td');
                    nameCell.textContent = file.name;
                    row.appendChild(nameCell);

                    // Tipo do arquivo
                    const typeCell = document.createElement('td');
                    typeCell.textContent = file.type || getFileExtension(file.name);
                    row.appendChild(typeCell);

                    // Tamanho do arquivo
                    const sizeCell = document.createElement('td');
                    sizeCell.textContent = formatFileSize(file.size);
                    row.appendChild(sizeCell);

                    // Status
                    const statusCell = document.createElement('td');
                    const isValid = isValidFile(file);
                    statusCell.innerHTML = isValid
                        ? '<span class="badge bg-success">Válido</span>'
                        : '<span class="badge bg-danger">Inválido</span>';
                    row.appendChild(statusCell);

                    // Ações
                    const actionCell = document.createElement('td');
                    const removeBtn = document.createElement('button');
                    removeBtn.className = 'btn btn-sm btn-outline-danger';
                    removeBtn.innerHTML = '<i class="bi bi-trash"></i>';
                    removeBtn.onclick = () => removeFile(index);
                    actionCell.appendChild(removeBtn);
                    row.appendChild(actionCell);

                    // Adicionar linha à tabela
                    fileList.appendChild(row);
                });

                // Atualizar tamanho total
                totalSizeBadge.textContent = formatFileSize(totalSize);

                // Verificar se podemos fazer upload (tamanho e tipos válidos)
                const isValidUpload = totalSize <= MAX_SIZE_BYTES &&
                                      selectedFiles.every(isValidFile);

                submitBtn.disabled = !isValidUpload;

                if (!isValidUpload) {
                    if (totalSize > MAX_SIZE_BYTES) {
                        showMessage('error', 'O tamanho total dos arquivos excede o limite de ' + MAX_SIZE_MB + 'MB');
                    } else {
                        showMessage('error', 'Existem arquivos com tipos inválidos');
                    }
                } else {
                    messageArea.innerHTML = '';
                }
            } else {
                fileListContainer.classList.add('d-none');
                submitBtn.classList.add('d-none');
                clearBtn.classList.add('d-none');
                messageArea.innerHTML = '';
            }
        }

        function addFiles(fileList) {
            // Convertendo FileList para Array para facilitar manipulação
            const filesArray = Array.from(fileList);

            // Calculando tamanho total incluindo os novos arquivos
            const newTotalSize = totalSize + filesArray.reduce((sum, file) => sum + file.size, 0);

            // Verificando tipos de arquivo
            const invalidFiles = filesArray.filter(file => !isValidFile(file));

            // Avisar sobre arquivos inválidos
            if (invalidFiles.length > 0) {
                const invalidNames = invalidFiles.map(f => f.name).join(', ');
                showMessage('warning', 'Tipo(s) de arquivo inválido(s): ' + invalidNames);
            }

            // Verificar tamanho
            if (newTotalSize > MAX_SIZE_BYTES) {
                showMessage('error', 'O tamanho total excede o limite de ' + MAX_SIZE_MB + 'MB');
            }

            // Adicionar arquivos válidos à seleção
            filesArray.forEach(file => {
                if (isValidFile(file)) {
                    selectedFiles.push(file);
                }
            });

            // Recalcular tamanho total
            totalSize = selectedFiles.reduce((sum, file) => sum + file.size, 0);

            // Atualizar a interface
            updateFileList();
        }

        function removeFile(index) {
            // Atualizar tamanho total
            totalSize -= selectedFiles[index].size;

            // Remover arquivo
            selectedFiles.splice(index, 1);

            // Atualizar interface
            updateFileList();
        }

        function isValidFile(file) {
            const extension = getFileExtension(file.name).toLowerCase();
            return VALID_EXTENSIONS.includes(extension);
        }

        function getFileExtension(filename) {
            return '.' + filename.split('.').pop().toLowerCase();
        }

        function formatFileSize(bytes) {
            if (bytes === 0) return '0 Bytes';

            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));

            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        function clearFiles() {
            selectedFiles = [];
            totalSize = 0;
            updateFileList();
            fileInput.value = '';
        }

        function showMessage(type, message) {
            // Limpar mensagens existentes
            messageArea.innerHTML = '';

            // Criar novo alerta
            const alert = document.createElement('div');
            alert.className = 'alert alert-' + (type === 'error' ? 'danger' : type) + ' alert-dismissible fade show';
            alert.innerHTML =
                message +
                '<button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Fechar"></button>';

            messageArea.appendChild(alert);
        }

        function resetForm() {
            clearFiles();
            updateProgressBar(0);
        }

        function updateProgressBar(percent) {
            const progressBar = document.querySelector('.progress-bar');
            const progressText = document.getElementById('progress-text');

            if (progressBar && progressText) {
                progressBar.style.width = percent + '%';
                progressBar.setAttribute('aria-valuenow', percent);
                progressText.textContent = percent + '%';
            }
        }

        // Função para atualizar a tabela de histórico com arquivos processados
        function updateUploadHistory(files) {
            // Limpar a mensagem "Nenhum arquivo processado" se existir
            const emptyRow = uploadHistoryTable.querySelector('tr td[colspan="5"]');
            if (emptyRow) {
                uploadHistoryTable.innerHTML = '';
            }

            // Adicionar cada arquivo à tabela de histórico
            files.forEach(file => {
                const row = document.createElement('tr');

                // Nome do arquivo
                const nameCell = document.createElement('td');
                nameCell.textContent = file.name;
                row.appendChild(nameCell);

                // Tamanho do arquivo
                const sizeCell = document.createElement('td');
                sizeCell.textContent = file.size;
                row.appendChild(sizeCell);

                // Data do upload
                const dateCell = document.createElement('td');
                dateCell.textContent = file.timestamp;
                row.appendChild(dateCell);

                // Status
                const statusCell = document.createElement('td');
                statusCell.innerHTML = '<span class="badge bg-success">Processado</span>';
                row.appendChild(statusCell);

                // Ações
                const actionCell = document.createElement('td');
                const deleteBtn = document.createElement('button');
                deleteBtn.className = 'btn btn-sm btn-outline-danger';
                deleteBtn.innerHTML = '<i class="bi bi-trash"></i>';
                deleteBtn.onclick = () => deleteProcessedFile(file.name);
                actionCell.appendChild(deleteBtn);
                row.appendChild(actionCell);

                // Adicionar à tabela
                uploadHistoryTable.appendChild(row);
            });
        }

        // Função para simular a exclusão de um arquivo processado
        function deleteProcessedFile(fileName) {
            // Em uma implementação real, aqui você faria uma chamada ao backend para excluir o arquivo
            if (confirm('Tem certeza que deseja remover o arquivo ' + fileName + '?')) {
                // Por enquanto, vamos apenas remover da tabela
                const rows = uploadHistoryTable.querySelectorAll('tr');
                rows.forEach(row => {
                    if (row.cells[0].textContent === fileName) {
                        row.remove();
                    }
                });

                // Se não houver mais arquivos, exibir mensagem
                if (uploadHistoryTable.children.length === 0) {
                    uploadHistoryTable.innerHTML = '<tr><td colspan="5" class="text-center text-muted">Nenhum arquivo processado</td></tr>';
                }
            }
        }

        // Event listeners
        selectFilesBtn.addEventListener('click', () => {
            fileInput.click();
        });

        fileInput.addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                addFiles(e.target.files);
            }
        });

        clearBtn.addEventListener('click', clearFiles);

        submitBtn.addEventListener('click', () => {
            if (selectedFiles.length > 0) {
                // Substituir os arquivos no input de arquivo do formulário
                const dataTransfer = new DataTransfer();
                selectedFiles.forEach(file => {
                    dataTransfer.items.add(file);
                });
                fileInput.files = dataTransfer.files;

                // Inicializar barra de progresso
                updateProgressBar(0);

                // Submeter o formulário
                uploadForm.dispatchEvent(new Event('submit', { bubbles: true }));
            }
        });

        // Eventos Drag & Drop
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            dropArea.addEventListener(eventName, preventDefaults, false);
            document.body.addEventListener(eventName, preventDefaults, false);
        });

        function preventDefaults(e) {
            e.preventDefault();
            e.stopPropagation();
        }

        ['dragenter', 'dragover'].forEach(eventName => {
            dropArea.addEventListener(eventName, () => {
                dropArea.classList.add('border-primary');
                dropArea.classList.add('bg-light');
            });
        });

        ['dragleave', 'drop'].forEach(eventName => {
            dropArea.addEventListener(eventName, () => {
                dropArea.classList.remove('border-primary');
                dropArea.classList.remove('bg-light');
            });
        });

        dropArea.addEventListener('drop', (e) => {
            const dt = e.dataTransfer;
            const files = dt.files;

            if (files.length > 0) {
                addFiles(files);
            }
        });

        // Adicionar listener para eventos HTMX de progresso
        document.body.addEventListener('htmx:xhr:progress', (event) => {
            if (event.detail.xhr.upload) {
                const percent = Math.round((event.detail.loaded / event.detail.total) * 100);
                updateProgressBar(percent);
            }
        });

        // Adicionar listener para processar a resposta do servidor após o upload
        document.body.addEventListener('htmx:afterOnLoad', function(event) {
            if (event.detail.elt && event.detail.elt.id === 'upload-form') {
                try {
                    // Tentar parsear a resposta como JSON
                    const response = JSON.parse(event.detail.xhr.responseText);

                    if (response.success && response.files) {
                        // Adicionar os arquivos processados à tabela de histórico
                        updateUploadHistory(response.files);

                        // Exibir mensagem de sucesso
                        showMessage('success', response.message || 'Arquivos processados com sucesso!');
                    } else {
                        // Exibir mensagem de erro
                        showMessage('error', response.message || 'Erro ao processar os arquivos.');
                    }
                } catch (error) {
                    console.error('Erro ao processar resposta:', error);
                    showMessage('error', 'Erro ao processar a resposta do servidor.');
                }
            }
        });
    </script>
`)
