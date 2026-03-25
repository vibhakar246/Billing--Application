# 🍽️ RestroBilling - Smart Restaurant Billing System

[![Jenkins](https://img.shields.io/badge/Jenkins-CI/CD-blue?logo=jenkins)](https://www.jenkins.io/)
[![Docker](https://img.shields.io/badge/Docker-Container-blue?logo=docker)](https://www.docker.com/)
[![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/HTML)
[![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/CSS)
[![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)

A modern, responsive restaurant billing system with real-time cart management, GST calculation, and bill generation. Complete CI/CD pipeline with Jenkins and Docker.

---

## 📸 Screenshots

### 🖥️ Restaurant Web Application
![Restaurant Billing UI](./screenshots/restaurant-webui.png)
*The main restaurant billing interface showing menu items, cart system, and bill generation*

### 🔧 Jenkins CI/CD Pipeline
![Jenkins Pipeline](./screenshots/jenkins-pipeline.png)
*Automated CI/CD pipeline showing successful build, test, and deployment stages*

---

## 🏗️ System Architecture

```mermaid
graph TB
    subgraph Frontend["Frontend Layer"]
        A[HTML/CSS/JS]
        B[Restaurant UI]
        C[Cart Management]
        D[Bill Generation]
    end
    
    subgraph CICD["CI/CD Pipeline"]
        E[GitHub Repository]
        F[Jenkins Build]
        G[Docker Build]
        H[Test Container]
        I[Deploy Locally]
    end
    
    subgraph Deployment["Deployment Layer"]
        J[Docker Container]
        K[Nginx Server]
        L[Localhost:8081]
    end
    
    A --> B
    B --> C
    C --> D
    
    E --> F
    F --> G
    G --> H
    H --> I
    
    I --> J
    J --> K
    K --> L
