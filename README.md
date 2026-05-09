# Healthy Paws - Platform

Welcome to the Healthy Paws platform. This repository contains the full stack for the pet clinic management system, including the backend service, frontend application, and Nginx gateway.

## 🚀 Quick Start (Docker)

The easiest way to run the entire platform is using Docker Compose.

1.  **Start the platform**:
    ```bash
    docker-compose up --build
    ```
2.  **Reset Database**:
    If you need to wipe the database and start fresh with the latest schema:
    ```bash
    docker-compose down -v
    docker-compose up --build
    ```

## 🛠️ API Endpoints

Once the application is running, you can interact with the backend via the Nginx gateway on port **80**.

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `http://localhost/api/auth/register` | `POST` | User & Doctor Registration |
| `http://localhost/api/auth/login` | `POST` | User Authentication |
| `http://localhost/graphql` | `POST` | GraphQL API (Core Logic) |
