// Funcionalidade de troca de tema
document.addEventListener('DOMContentLoaded', function() {
  // Verifica se há um tema salvo no localStorage
  const savedTheme = localStorage.getItem('theme') || 'light';
  applyTheme(savedTheme);

  // Adiciona o evento de clique para o toggle de tema
  document.getElementById('themeToggle').addEventListener('click', function() {
    const currentTheme = document.documentElement.getAttribute('data-bs-theme');
    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    applyTheme(newTheme);
    localStorage.setItem('theme', newTheme);
  });

  function applyTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme);

    // Atualiza os ícones visíveis
    if (theme === 'dark') {
      document.getElementById('lightThemeIcon').style.display = 'none';
      document.getElementById('darkThemeIcon').style.display = 'inline';
    } else {
      document.getElementById('lightThemeIcon').style.display = 'inline';
      document.getElementById('darkThemeIcon').style.display = 'none';
    }

    // Atualiza as classes da navbar com base no tema
    const navbar = document.querySelector('.navbar');
    if (theme === 'dark') {
      navbar.classList.remove('navbar-light', 'bg-light');
      navbar.classList.add('navbar-dark', 'bg-dark');
    } else {
      navbar.classList.remove('navbar-dark', 'bg-dark');
      navbar.classList.add('navbar-light', 'bg-light');
    }
  }
});