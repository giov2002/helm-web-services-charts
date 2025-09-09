#!/bin/bash

# Script d'installation et configuration CI pour projet Minikube + Helm
# Adapté pour Debian 12 avec Ansible, Docker, Kubernetes, Helm

set -e

# Configuration
PROJECT_NAME="ansible-lab"
CHARTS_PATH="web-services/helm/charts"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}🚀 SETUP CI MINIKUBE + HELM PROJECT${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

check_prerequisites() {
    print_step "Vérification des prérequis..."
    
    # OS Check
    if [[ ! -f /etc/debian_version ]]; then
        print_warning "Ce script est optimisé pour Debian 12"
    else
        print_success "OS: Debian $(cat /etc/debian_version)"
    fi
    
    # Outils requis
    local tools=("docker" "minikube" "kubectl" "helm" "ansible" "git" "curl" "jq")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_success "$tool trouvé: $(command -v "$tool")"
        else
            missing+=("$tool")
            print_error "$tool non trouvé"
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Outils manquants: ${missing[*]}"
        print_info "Installez-les avec:"
        echo "sudo apt update && sudo apt install -y ${missing[*]}"
        return 1
    fi
}

check_project_structure() {
    print_step "Vérification de la structure du projet..."
    
    # Vérifier qu'on est dans le bon répertoire
    if [[ ! -d "$CHARTS_PATH" ]]; then
        print_error "Répertoire charts non trouvé: $CHARTS_PATH"
        print_info "Assurez-vous d'être dans le répertoire racine du projet"
        return 1
    fi
    
    print_success "Structure de charts trouvée: $CHARTS_PATH"
    
    # Lister les charts disponibles
    echo ""
    print_info "Charts Helm détectés:"
    find "$CHARTS_PATH" -maxdepth 2 -name "Chart.yaml" | while read chart; do
        chart_dir=$(dirname "$chart")
        chart_name=$(basename "$chart_dir")
        echo "  📦 $chart_name"
    done
}

check_minikube_status() {
    print_step "Vérification de l'environnement Minikube..."
    
    if minikube status &> /dev/null; then
        print_success "Minikube est actif"
        print_info "Profil: $(minikube profile)"
        print_info "Version K8s: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
    else
        print_warning "Minikube n'est pas actif"
        echo ""
        read -p "🚀 Démarrer Minikube maintenant ? [y/N]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Démarrage de Minikube..."
            minikube start --driver=docker --memory=4096 --cpus=2
            print_success "Minikube démarré!"
        else
            print_info "Minikube restera inactif (vous pourrez le démarrer plus tard)"
        fi
    fi
}

setup_github_config() {
    print_step "Configuration GitHub..."
    
    # Auto-détection du repo Git
    if [[ -d ".git" ]]; then
        REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            AUTO_OWNER="${BASH_REMATCH[1]}"
            AUTO_REPO="${BASH_REMATCH[2]}"
            print_success "Repo détecté automatiquement: $AUTO_OWNER/$AUTO_REPO"
            
            # Mise à jour du fichier de config
            sed -i "s/VOTRE_USERNAME/$AUTO_OWNER/g" ansible-minikube-config.yml 2>/dev/null || true
            sed -i "s/ansible-lab/$AUTO_REPO/g" ansible-minikube-config.yml 2>/dev/null || true
            
        else
            print_warning "Impossible de détecter le repo GitHub depuis l'URL Git"
        fi
    else
        print_warning "Pas de repo Git détecté"
    fi
    
    # Configuration du token
    if [[ -z "$GITHUB_PAT" ]]; then
        print_warning "Variable GITHUB_PAT non définie"
        print_info "Pour configurer le token GitHub:"
        echo "  1. Allez sur https://github.com/settings/tokens"
        echo "  2. Créez un token avec scopes: repo, workflow"
        echo "  3. Exportez-le: export GITHUB_PAT='your_token_here'"
        echo ""
        read -p "📋 Avez-vous déjà un token GitHub ? [y/N]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "🔑 Collez votre token (masqué): " -s github_token
            echo ""
            export GITHUB_PAT="$github_token"
            print_success "Token configuré pour cette session"
        fi
    else
        print_success "Token GitHub détecté"
    fi
}

create_workflow_files() {
    print_step "Création des fichiers workflow..."
    
    # Créer le répertoire .github/workflows s'il n'existe pas
    mkdir -p .github/workflows
    
    # Vérifier si les workflows existent déjà
    if [[ -f ".github/workflows/helm-full-check.yml" ]]; then
        print_success "Workflow CI déjà présent"
    else
        print_warning "Workflow CI manquant"
        print_info "Copiez le contenu du workflow helm-full-check.yml dans .github/workflows/"
    fi
}

test_ci_trigger() {
    print_step "Test du déclenchement CI..."
    
    if [[ -z "$GITHUB_PAT" ]]; then
        print_warning "Impossible de tester sans token GitHub"
        return 0
    fi
    
    print_info "Test en mode dry-run..."
    
    # Test avec le playbook Ansible
    if [[ -f "minikube-ci-trigger.yml" ]]; then
        ansible-playbook minikube-ci-trigger.yml --check -v
        print_success "Playbook Ansible validé"
    else
        print_warning "Playbook minikube-ci-trigger.yml non trouvé"
    fi
}

show_next_steps() {
    print_step "Prochaines étapes..."
    
    echo ""
    print_info "🎯 Pour déclencher le CI:"
    echo "  # Méthode 1: Playbook Ansible"
    echo "  ansible-playbook minikube-ci-trigger.yml -e check_type=full"
    echo ""
    echo "  # Méthode 2: Script bash"
    echo "  chmod +x trigger-ci.sh && ./trigger-ci.sh full"
    echo ""
    
    print_info "🔍 Types de vérification disponibles:"
    echo "  - full          : Validation complète (recommandé)"
    echo "  - security-only : Audit sécurité uniquement" 
    echo "  - lint-only     : Lint YAML uniquement"
    echo ""
    
    print_info "📋 Workflow du projet:"
    echo "  1. 🔍 CI validation (GitHub Actions)"
    echo "  2. ✅ Si OK → Création du CD"
    echo "  3. 🚀 CD déploiement (Minikube)"
    echo "  4. 📊 Monitoring des services"
    echo ""
    
    print_info "🌐 Liens utiles:"
    echo "  - Actions GitHub: https://github.com/{owner}/{repo}/actions"
    echo "  - Dashboard Minikube: minikube dashboard"
    echo "  - Logs Kubectl: kubectl logs -f deployment/{service}"
}

# Execution principale
main() {
    print_header
    
    print_info "🎯 Setup pour projet: Ansible + Docker + Kubernetes + Helm + CI/CD"
    print_info "🏗️ Environnement cible: Debian 12 + Minikube"
    echo ""
    
    check_prerequisites || exit 1
    echo ""
    
    check_project_structure || exit 1
    echo ""
    
    check_minikube_status
    echo ""
    
    setup_github_config
    echo ""
    
    create_workflow_files
    echo ""
    
    test_ci_trigger
    echo ""
    
    show_next_steps
    
    echo ""
    print_success "🎉 Setup terminé!"
    print_info "Vous pouvez maintenant déclencher votre CI Helm Charts!"
}

# Point d'entrée
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
