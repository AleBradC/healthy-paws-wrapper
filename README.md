# Healthy Paws - Platform

Welcome to the Healthy Paws platform. This repository is a wrapper that orchestrates the entire stack, including the backend service, frontend application, and Nginx gateway.

## 🏗️ Architecture

- **Backend:** [healthy-paws-service](./healthy-paws-service) (Node.js, Express, GraphQL)
- **Frontend:** [healty-paws-frontend](./healty-paws-frontend) (React, Vite, Apollo)
- **Gateway:** Nginx (Routes traffic to the appropriate service)

---

## 🚀 Quick Start (Docker Compose)

The easiest way to run the entire platform with all dependencies pre-configured.

### 1. Initialize Submodules
This repository uses Git submodules. Ensure you have the latest code for all components:
```bash
git submodule update --init --recursive
```

### 2. Start the platform
```bash
docker-compose up --build
```
- **Frontend:** [http://localhost](http://localhost)
- **API Gateway:** [http://localhost/api](http://localhost/api)
- **GraphQL Playground:** [http://localhost/graphql](http://localhost/graphql)

---

## 🛠️ Manual Setup (Local Development)

If you prefer to run services individually without Docker for a faster development cycle:

### 1. Prerequisites
- **Node.js** (v20+)
- **PostgreSQL** (v15+)

### 2. Backend Setup
Navigate to the [backend directory](./healthy-paws-service):
```bash
cd healthy-paws-service
npm install
# Create .env based on the template in README.md
npm run watch
```

### 3. Frontend Setup
Navigate to the [frontend directory](./healty-paws-frontend):
```bash
cd healty-paws-frontend
npm install --legacy-peer-deps
npm run dev
```

---

## 💾 Database Management

### Resetting the Environment
To wipe the database volumes and start fresh with the latest schema:
```bash
docker-compose down -v
docker-compose up --build
```

---

## 🛠️ API Endpoints Reference

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `http://localhost/api/auth/register` | `POST` | User & Doctor Registration |
| `http://localhost/api/auth/login` | `POST` | User Authentication |
| `http://localhost/graphql` | `POST` | GraphQL API (Core Logic) |
