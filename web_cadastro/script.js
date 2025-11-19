// Configurações da API
const API_BASE_URL = 'http://localhost:5000/api';

// Elementos DOM
const form = document.getElementById('registration-form');
const submitBtn = document.getElementById('submit-btn');
const btnText = document.querySelector('.btn-text');
const spinner = document.getElementById('spinner');
const successMessage = document.getElementById('success-message');
const errorMessage = document.getElementById('error-message');
const errorText = document.getElementById('error-text');
const userEmail = document.getElementById('user-email');
const userPassword = document.getElementById('user-password');

// Campos do formulário
const nameField = document.getElementById('name');
const emailField = document.getElementById('email');
const passwordField = document.getElementById('password');
const confirmPasswordField = document.getElementById('confirm-password');
const termsField = document.getElementById('terms');

// Informações do dispositivo
const installationIdSpan = document.getElementById('installation-id');
const androidIdSpan = document.getElementById('android-id');

// Variáveis globais
let deviceInfo = {};

// Inicialização
document.addEventListener('DOMContentLoaded', function() {
    initializePage();
    setupFormValidation();
    setupFormSubmission();
});

// Inicializar página
function initializePage() {
    // Obter parâmetros da URL
    const urlParams = new URLSearchParams(window.location.search);
    const installationId = urlParams.get('installationId');
    const androidId = urlParams.get('androidId');

    deviceInfo = {
        installationId: installationId || 'N/A',
        androidId: androidId || 'N/A'
    };

    // Exibir informações do dispositivo
    installationIdSpan.textContent = deviceInfo.installationId;
    androidIdSpan.textContent = deviceInfo.androidId;

    console.log('Informações do dispositivo:', deviceInfo);
}

// Configurar validação do formulário
function setupFormValidation() {
    // Validação em tempo real
    nameField.addEventListener('blur', () => validateField('name'));
    emailField.addEventListener('blur', () => validateField('email'));
    passwordField.addEventListener('blur', () => validateField('password'));
    confirmPasswordField.addEventListener('blur', () => validateField('confirm-password'));
    termsField.addEventListener('change', () => validateField('terms'));

    // Validação da confirmação de senha
    confirmPasswordField.addEventListener('input', function() {
        if (this.value !== passwordField.value) {
            showFieldError('confirm-password', 'As senhas não coincidem');
        } else {
            hideFieldError('confirm-password');
        }
    });
}

// Configurar submissão do formulário
function setupFormSubmission() {
    form.addEventListener('submit', function(e) {
        e.preventDefault();

        if (validateForm()) {
            submitRegistration();
        }
    });
}

// Validar campo individual
function validateField(fieldName) {
    const field = document.getElementById(fieldName);
    const value = field.value.trim();
    let isValid = true;
    let errorMessage = '';

    switch (fieldName) {
        case 'name':
            if (!value) {
                errorMessage = 'Nome é obrigatório';
                isValid = false;
            } else if (value.length < 2) {
                errorMessage = 'Nome deve ter pelo menos 2 caracteres';
                isValid = false;
            }
            break;

        case 'email':
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!value) {
                errorMessage = 'E-mail é obrigatório';
                isValid = false;
            } else if (!emailRegex.test(value)) {
                errorMessage = 'E-mail inválido';
                isValid = false;
            }
            break;

        case 'password':
            if (!value) {
                errorMessage = 'Senha é obrigatória';
                isValid = false;
            } else if (value.length < 6) {
                errorMessage = 'Senha deve ter pelo menos 6 caracteres';
                isValid = false;
            }
            break;

        case 'confirm-password':
            if (!value) {
                errorMessage = 'Confirmação de senha é obrigatória';
                isValid = false;
            } else if (value !== passwordField.value) {
                errorMessage = 'As senhas não coincidem';
                isValid = false;
            }
            break;

        case 'terms':
            if (!field.checked) {
                errorMessage = 'Você deve aceitar os termos';
                isValid = false;
            }
            break;
    }

    if (isValid) {
        hideFieldError(fieldName);
    } else {
        showFieldError(fieldName, errorMessage);
    }

    return isValid;
}

// Validar formulário completo
function validateForm() {
    const fields = ['name', 'email', 'password', 'confirm-password', 'terms'];
    let isValid = true;

    fields.forEach(field => {
        if (!validateField(field)) {
            isValid = false;
        }
    });

    return isValid;
}

// Mostrar erro do campo
function showFieldError(fieldName, message) {
    const errorElement = document.getElementById(`${fieldName}-error`);
    errorElement.textContent = message;
    errorElement.style.display = 'block';
    document.getElementById(fieldName).classList.add('error');
}

// Ocultar erro do campo
function hideFieldError(fieldName) {
    const errorElement = document.getElementById(`${fieldName}-error`);
    errorElement.style.display = 'none';
    const field = document.getElementById(fieldName);
    if (field) {
        field.classList.remove('error');
    }
}

// Enviar cadastro
async function submitRegistration() {
    setLoadingState(true);

    const formData = {
        name: nameField.value.trim(),
        email: emailField.value.trim(),
        password: passwordField.value,
        installationId: deviceInfo.installationId,
        androidId: deviceInfo.androidId
    };

    try {
        console.log('Enviando dados de cadastro:', formData);

        const response = await fetch(`${API_BASE_URL}/users/register`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        });

        const result = await response.json();

        if (response.ok) {
            console.log('Cadastro realizado com sucesso:', result);
            showSuccess(result.user, formData.password);
            // Tentar login automático após 3 segundos
            setTimeout(() => autoLogin(formData.email, formData.password), 3000);
        } else {
            console.error('Erro no cadastro:', result);
            showError(result.error || 'Erro desconhecido no cadastro');
        }
    } catch (error) {
        console.error('Erro na requisição:', error);
        showError('Erro de conexão. Verifique sua internet e tente novamente.');
    } finally {
        setLoadingState(false);
    }
}

// Login automático
async function autoLogin(email, password) {
    try {
        console.log('Tentando login automático...');

        const response = await fetch(`${API_BASE_URL}/users/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ email, password })
        });

        const result = await response.json();

        if (response.ok) {
            console.log('Login automático realizado:', result);

            // Salvar token no localStorage para uso futuro
            localStorage.setItem('auth_token', result.token);
            localStorage.setItem('user_info', JSON.stringify(result.user));

            // Redirecionar para o app Flutter (se estiver rodando)
            // Como estamos em um navegador separado, vamos mostrar instruções
            showAutoLoginSuccess(result.user);
        } else {
            console.error('Erro no login automático:', result);
            // Mesmo com erro no login, o cadastro foi bem-sucedido
            showAutoLoginError();
        }
    } catch (error) {
        console.error('Erro no login automático:', error);
        showAutoLoginError();
    }
}

// Estados da UI
function setLoadingState(isLoading) {
    submitBtn.disabled = isLoading;
    submitBtn.classList.toggle('loading', isLoading);

    if (isLoading) {
        btnText.textContent = 'Cadastrando...';
    } else {
        btnText.textContent = 'Cadastrar';
    }
}

function showSuccess(user, password) {
    form.style.display = 'none';
    successMessage.style.display = 'block';
    userEmail.textContent = user.email;
    userPassword.textContent = password;
}

function showError(message) {
    errorText.textContent = message;
    errorMessage.style.display = 'block';
}

function hideError() {
    errorMessage.style.display = 'none';
}

function showAutoLoginSuccess(user) {
    const successDiv = document.createElement('div');
    successDiv.className = 'auto-login-success';
    successDiv.innerHTML = `
        <div style="background: #e8f5e8; border: 1px solid #4caf50; padding: 20px; border-radius: 8px; margin-top: 20px;">
            <h4 style="color: #2e7d32; margin-bottom: 10px;">✓ Login automático realizado!</h4>
            <p style="color: #2e7d32; margin-bottom: 15px;">Você foi logado automaticamente no sistema.</p>
            <p style="font-size: 0.9rem; color: #666;">
                <strong>Usuário logado:</strong> ${user.name} (${user.email})
            </p>
            <p style="font-size: 0.9rem; color: #666; margin-top: 10px;">
                Você pode fechar esta aba e voltar ao aplicativo TV Multimidia.
            </p>
        </div>
    `;

    successMessage.appendChild(successDiv);
}

function showAutoLoginError() {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'auto-login-error';
    errorDiv.innerHTML = `
        <div style="background: #fff3e0; border: 1px solid #ff9800; padding: 20px; border-radius: 8px; margin-top: 20px;">
            <h4 style="color: #f57c00; margin-bottom: 10px;">⚠ Login automático falhou</h4>
            <p style="color: #f57c00; margin-bottom: 15px;">
                O cadastro foi realizado com sucesso, mas não foi possível fazer login automático.
            </p>
            <p style="font-size: 0.9rem; color: #666;">
                Você pode fazer login manualmente no aplicativo TV Multimidia usando suas credenciais.
            </p>
        </div>
    `;

    successMessage.appendChild(errorDiv);
}

// Utilitários
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}