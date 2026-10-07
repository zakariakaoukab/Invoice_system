# Rapport de Stage : Dar Belamri POS & Invoicing System
**A comprehensive guide to help you write your internship report.**

---

## 1. Introduction & Contexte du Projet
**Nom du Projet :** Dar Belamri POS & Invoicing System
**Objectif Principal :** Digitaliser et automatiser la gestion des ventes, du stock, et de la facturation pour l'entreprise "Dar Belamri" via une application multiplateforme performante.
**Problématique :** Les petites et moyennes entreprises dépendent souvent de processus manuels (carnets, feuilles de calcul) pour gérer leurs stocks et leurs ventes, ce qui entraîne des erreurs de calcul, des pertes de données, et une incapacité à analyser les performances de l'entreprise en temps réel.
**Solution Proposée :** Une solution ERP/POS centralisée, connectée au Cloud, offrant une caisse enregistreuse numérique, une gestion de stock en temps réel, une génération automatique de factures PDF, et un assistant virtuel IA.

---

## 2. Architecture & Choix Technologiques
Ce projet utilise une architecture moderne et robuste, séparant clairement la logique métier de l'interface utilisateur.

### 2.1 Front-End (Client)
*   **Framework :** Flutter (Dart) - Permet de compiler l'application pour Windows, Web, et Mobile à partir d'une seule base de code.
*   **Gestion d'État (State Management) :** Riverpod (`flutter_riverpod`) - Choisi pour sa sécurité à la compilation, sa gestion asynchrone simplifiée (AsyncValue) et son architecture réactive.
*   **Routage :** GoRouter (`go_router`) - Gestion de la navigation basée sur les URLs, indispensable pour les applications Web/Desktop et la protection des routes (guards pour l'authentification).
*   **Design System :** "Enterprise Light Theme" personnalisé, utilisant des couleurs professionnelles (Enterprise Blue, Dark Charcoal) pour une lisibilité maximale en environnement de vente. Support natif du format RTL (Right-to-Left) pour la langue Arabe.

### 2.2 Back-End (BaaS - Backend as a Service)
*   **Base de Données :** Firebase Cloud Firestore - Base de données NoSQL en temps réel. Permet la synchronisation instantanée du stock sur tous les appareils de la boutique.
*   **Authentification :** Firebase Auth - Sécurisation de l'accès à l'application.
*   **Stockage de Fichiers :** Firebase Storage - Hébergement des images des produits et des factures archivées.

### 2.3 Intégration IA (L'innovation majeure)
*   **API :** Google Gemini API (`google_generative_ai`)
*   **Modèle utilisé :** Gemini 2.5 Flash (Ultra-rapide, optimisé pour les réponses instantanées).
*   **Architecture RAG (Retrieval-Augmented Generation) :** Le backend récupère dynamiquement les données Firestore (stock actuel, dernières commandes), les convertit en JSON, et les injecte dans le prompt du modèle. Cela permet à l'IA de répondre avec précision sur l'état *réel* de l'entreprise.

---

## 3. Les Modules Fonctionnels (Features)

### 3.1 Module POS (Point of Sale)
*   Interface de caisse rapide et ergonomique.
*   Panier d'achat dynamique avec calcul en temps réel du sous-total, des taxes éventuelles, et du total.
*   Décrémentation automatique du stock lors de la validation d'une commande.

### 3.2 Module d'Inventaire (Products)
*   Modèle de données `Product` (`id`, `name`, `price`, `stockQty`, `imageUrl`, etc.).
*   Affichage en grille des produits avec indicateurs visuels du niveau de stock.

### 3.3 Module Analytique (Dashboard)
*   **Indicateurs Clés de Performance (KPI) :** Chiffre d'affaires mensuel, Nombre de commandes, Panier moyen.
*   **Visualisation de données :** Graphiques interactifs développés avec `fl_chart`.
*   **Top Produits :** Classement automatique des meilleures ventes.

### 3.4 Module de Facturation (Invoicing)
*   Génération de fichiers PDF natifs via les packages `pdf` et `printing`.
*   Création dynamique d'un document formaté (A4 ou Ticket de caisse) reprenant l'en-tête de l'entreprise, le détail de la commande, et le montant total.
*   Option d'impression directe ou d'exportation de la facture.

### 3.5 Assistant Virtuel IA (AI Business Assistant)
*   Chatbot intégré directement au tableau de bord.
*   **Cas d'usage :** Le gérant peut demander "Quels produits sont en rupture de stock ?" ou "Quel est mon chiffre d'affaires aujourd'hui ?" en langage naturel (Arabe, Français, Anglais), et l'IA analyse la base de données pour fournir une réponse immédiate.

---

## 4. Modélisation de la Base de Données (NoSQL)
L'approche NoSQL de Firestore nécessite une dénormalisation des données pour optimiser les lectures.

**Collection `users` :**
*   `uid` (String, Primary Key)
*   `name` (String)
*   `role` (String: "admin", "cashier")

**Collection `products` :**
*   `id` (String)
*   `name` (String)
*   `price` (Double)
*   `stockQty` (Int)

**Collection `orders` :**
*   `id` (String - ex: FACT-2026-001)
*   `totalAmount` (Double)
*   `createdAt` (Timestamp)
*   `orderItems` (Array of Objects):
    *   `productId`, `productName`, `quantity`, `unitPrice`

*(Note pour le jury : Expliquez que vous stockez les détails du produit directement dans `orderItems` pour garantir que si le prix du produit change dans le futur, le montant de l'ancienne facture reste intact. C'est un point très apprécié des jurys).*

---

## 5. Défis Techniques Surmontés (Pour votre soutenance)
Voici d'excellents points de discussion pour montrer votre niveau technique au jury :
1.  **La Gestion de l'État Complexe :** L'utilisation de `Riverpod` pour éviter les fuites de mémoire et gérer les "AsyncValues" (états de chargement, de succès et d'erreur) lors de la communication avec Firestore.
2.  **Sécurité des Données & API :** L'utilisation de la librairie `flutter_dotenv` pour sécuriser la clé API Gemini, évitant ainsi de l'exposer dans le code source ou sur GitHub.
3.  **L'intégration de l'Intelligence Artificielle :** La conception du "Prompt System" qui traduit la base de données NoSQL en JSON structuré pour que le LLM Gemini puisse l'analyser et agir comme un analyste de données humain.

---

## 6. Conclusion & Évolutions Futures (Perspectives)
Bien que l'application soit fonctionnelle, plusieurs évolutions sont envisageables pour une V2 :
*   **Mode Hors-Ligne (Offline-First) :** Utiliser SQLite pour sauvegarder les commandes en cas de coupure Internet et les synchroniser avec Firebase au retour de la connexion.
*   **CRM Intégré :** Ajouter un système de gestion de crédit/dettes (Le "Carnet" digital) pour les clients fidèles.
*   **Support Hardware :** Intégration de lecteurs de codes-barres physiques et d'imprimantes thermiques Bluetooth.
