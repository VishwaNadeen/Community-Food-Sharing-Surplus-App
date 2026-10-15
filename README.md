# 🌍 Community Food Sharing Surplus App

<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=700&size=28&pause=1000&color=2ECC71&center=true&vCenter=true&width=750&lines=Share+Food%2C+Spread+Kindness+%F0%9F%8D%83;Reduce+Food+Waste+%F0%9F%8C%B1;Connect+Donors+with+Communities+%F0%9F%A4%9D;Together%2C+We+Can+Fight+Hunger+%E2%9D%A4%EF%B8%8F" alt="Animated project introduction" />

### 🍃 Turning Surplus Food into Hope

**A mobile application connecting food donors, NGOs, recipients, and volunteer drivers to reduce food waste and support communities in need.**

[![Flutter](https://img.shields.io/badge/Flutter-Mobile_App-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-Backend-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express.js-API-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com/)
[![TypeScript](https://img.shields.io/badge/TypeScript-Type_Safe-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Prisma](https://img.shields.io/badge/Prisma-ORM-2D3748?style=for-the-badge&logo=prisma&logoColor=white)](https://www.prisma.io/)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-Media_Storage-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)](https://cloudinary.com/)

[**Explore Repository**](https://github.com/VishwaNadeen/Community-Food-Sharing-Surplus-App) · [**Report an Issue**](https://github.com/VishwaNadeen/Community-Food-Sharing-Surplus-App/issues)

</div>

---

## 📖 About the Project

Food waste and food insecurity are significant challenges in many communities. At the same time, restaurants, businesses, and individuals may have surplus food that could help people in need.

The **Community Food Sharing Surplus App** is designed to bridge this gap through a digital food-sharing platform.

The application allows donors to share surplus food, NGOs to coordinate donations and distribution, recipients to discover and request available food, and volunteers to support delivery operations.

Our goal is to make food distribution more accessible, organized, and efficient while encouraging sustainable and community-driven food sharing.

## 🎯 Project Objectives

- 🌱 Reduce avoidable food waste.
- 🍱 Connect surplus food donors with people in need.
- 🤝 Support NGOs in coordinating food distribution.
- 🚚 Facilitate volunteer-based food delivery.
- 📱 Provide a convenient mobile platform for food sharing.
- ❤️ Encourage community participation and social responsibility.

## ✨ Key Features

<table>
<tr>
<td width="50%" valign="top">

### 🔐 Authentication & Profiles

- Role-based login
- User authentication
- Profile management
- Role-specific application access

</td>
<td width="50%" valign="top">

### 🍲 Donor Management

- Create food donations
- Manage donation information
- View donation-related activities
- Support food donation coordination

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 🛒 Recipient Management

- Browse available food donations
- View food donation details
- Submit food requests
- Track personal food requests

</td>
<td width="50%" valign="top">

### 🚚 Volunteer & Driver Management

- Access delivery-related features
- Support food collection and distribution
- Manage volunteer delivery activities

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 🏢 NGO Coordination

- NGO dashboard and administration
- Coordinate food requests and donations
- Support distribution management
- View impact-related information

</td>
<td width="50%" valign="top">

### ☁️ Media & API Integration

- Backend API integration
- Cloud-based image uploads
- Authentication middleware
- Data exchange between mobile and backend

</td>
</tr>
</table>

## 🔄 How the Application Works

```mermaid
flowchart TD
    A["🍲 Food Donor"] --> B["📱 Create Food Donation"]
    B --> C["🏢 NGO Coordination"]
    C --> D["📋 Manage and Coordinate Donations"]
    D --> E["🛒 Recipient Browses Available Food"]
    E --> F["📝 Recipient Requests Food"]
    F --> G["✅ NGO Reviews and Coordinates Requests"]
    G --> H["🚚 Volunteer / Driver Delivery"]
    H --> I["❤️ Food Reaches the Community"]

    style A fill:#d1fae5,stroke:#059669,color:#064e3b
    style B fill:#dbeafe,stroke:#2563eb,color:#1e3a8a
    style C fill:#f3e8ff,stroke:#9333ea,color:#581c87
    style D fill:#fef3c7,stroke:#d97706,color:#78350f
    style E fill:#cffafe,stroke:#0891b2,color:#164e63
    style F fill:#fce7f3,stroke:#db2777,color:#831843
    style G fill:#ede9fe,stroke:#7c3aed,color:#4c1d95
    style H fill:#ffedd5,stroke:#ea580c,color:#7c2d12
    style I fill:#d1fae5,stroke:#059669,color:#064e3b
```

*The diagram illustrates the overall collaboration between the application's main roles. Specific approval and delivery steps depend on the implemented workflow.*

## 👥 User Roles

| Role | Main Responsibilities |
|---|---|
| 🔐 Authentication | Secure login, role-based access, and user profiles |
| 🍲 Donor | Create and manage food donations |
| 🛒 Recipient | Browse donations and request food |
| 🚚 Volunteer / Driver | Support food delivery and distribution |
| 🏢 NGO Coordinator | Coordinate donations, requests, and distribution |

## 🛠️ Technology Stack

<div align="center">

| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev/) | Cross-platform mobile application |
| [Dart](https://dart.dev/) | Mobile application programming language |
| [Node.js](https://nodejs.org/) | Backend runtime |
| [Express.js](https://expressjs.com/) | Backend API framework |
| [TypeScript](https://www.typescriptlang.org/) | Type-safe backend development |
| [Prisma](https://www.prisma.io/) | Database ORM |
| [Cloudinary](https://cloudinary.com/) | Image and media management |
| [Git & GitHub](https://github.com/) | Version control and team collaboration |

</div>

## 🏗️ Project Architecture

The project is organized into a mobile frontend and a backend API.

```text
Community-Food-Sharing-Surplus-App/
│
├── frontend/
│   └── lib/
│       ├── models/
│       ├── providers/
│       └── screens/
│           ├── auth/
│           ├── donor/
│           ├── ngo/
│           ├── recipient/
│           └── volunteer/
│
├── backend/
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── routes/
│   │   ├── services/
│   │   └── app.ts
│   └── prisma/
│
├── README.md
├── CONTRIBUTING.md
└── .gitignore
```

*Note: This is a simplified architectural overview. Adjust folder names if your current repository structure differs.*

## 🚀 Getting Started

Follow these steps to run the application locally.

### Prerequisites

Install the following tools before starting:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Node.js](https://nodejs.org/)
- npm
- Git
- A configured database and the required environment variables
- Android Studio or another supported Flutter development environment

### 1. Clone the Repository

```bash
git clone https://github.com/VishwaNadeen/Community-Food-Sharing-Surplus-App.git

cd Community-Food-Sharing-Surplus-App
```

### 2. Set Up the Backend

```bash
cd backend
npm install
```

Create a `.env` file in the backend directory and configure the environment variables required by your backend, including database connectivity, authentication, and Cloudinary credentials.

Generate the Prisma client if required by your project configuration:

```bash
npx prisma generate
```

Start the development server:

```bash
npm run dev
```

*Database migrations or other database initialization steps may be required depending on your current Prisma configuration.*

### 3. Set Up the Flutter Application

Open a new terminal and navigate to the Flutter frontend directory.

```bash
cd frontend
flutter pub get
```

Check that a device or emulator is available:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

**Important:** Configure the mobile application's API base URL to point to your running backend. For an Android emulator, `10.0.2.2` typically refers to the host computer. A physical device generally needs the computer's reachable local network IP address.

## 🔒 Environment Configuration

Keep all secrets and credentials outside your source code.

Configure the appropriate environment variables for:

- Database connection
- Authentication and JWT
- Cloudinary media uploads
- Email services, if enabled

**Never commit your `.env` file, passwords, API secrets, or private credentials to GitHub.** Use a `.env.example` file containing placeholder values when documenting required configuration.

## 👨‍💻 Meet the Team

This project was developed collaboratively by four team members, with each member responsible for a specific part of the application.

<div align="center">

### 🌟 Our Development Team

</div>

<table>
<tr>
<th>Team Member</th>
<th>GitHub Username</th>
<th>Contribution</th>
</tr>
<tr>
<td><strong>Vishwa Nadeen</strong></td>
<td>HPVN Pathirana</td>
<td>Project setup, role-based login, authentication, login/profile functionality, and recipient module.</td>
</tr>
<tr>
<td><strong>Methma Sankalpani</strong></td>
<td>Sankaalpani GM</td>
<td>Volunteer and driver features, including delivery-related functionality.</td>
</tr>
<tr>
<td><strong>K. D. S. Nimesha</strong></td>
<td>K. D. S. Nimesha</td>
<td>Donor module and food donation features.</td>
</tr>
<tr>
<td><strong>S. P. T. Lakmini</strong></td>
<td>S. P. T. Lakmini</td>
<td>NGO module and NGO-related features.</td>
</tr>
</table>

We worked together to integrate our modules into a unified application and support the complete food-sharing process.

## 🌍 Social Impact

Our application aims to contribute to a more sustainable and supportive community.

- ♻️ **Sustainability:** Help reduce surplus food waste.
- ❤️ **Community Support:** Connect available food with people who need it.
- 🤝 **Collaboration:** Bring donors, NGOs, recipients, and volunteers together.
- 🚚 **Distribution:** Help coordinate food collection and delivery.
- 🌱 **Awareness:** Encourage responsible food-sharing practices.

## 🔮 Future Improvements

Potential enhancements for the application include:

- 🔔 Real-time notifications for donation and request updates.
- 📍 Improved location-based donation discovery.
- 🗺️ Enhanced delivery tracking and route planning.
- 📊 Expanded NGO impact analytics and reporting.
- ⭐ Donor and volunteer feedback systems.
- 🔐 Further authentication and security improvements.

These are proposed enhancements and are not necessarily implemented in the current version.

## 🤝 Contributing

Contributions, suggestions, and feedback are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Make and test your changes.
4. Commit your changes with a meaningful message.
5. Submit a pull request.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for information about team responsibilities and contributions.

## 📸 Screenshots & Demonstration

Screenshots of the donor, recipient, NGO, login, and volunteer screens can be added here to showcase the actual application interface.

To include a screenshot stored in your repository, use:

```markdown
![Recipient Dashboard](docs/screenshots/recipient-dashboard.png)
```

Replace the example path with the actual location of your screenshot. You can also add a link to a demonstration video once it is available.

## 📄 License

A license has not been specified in this README. If you plan to publish or distribute this project publicly, consider choosing an appropriate open-source license and adding a corresponding `LICENSE` file.

---

<div align="center">

### 💚 Share More. Waste Less. Care More.

**Every meal shared is a step toward a better community.**

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=18&pause=1200&color=00C853&center=true&vCenter=true&width=600&lines=Food+is+too+precious+to+waste.;Small+actions+create+big+changes.;Together+we+can+make+a+difference." alt="Animated closing message" />

**Built with care by the Community Food Sharing Surplus App team.**

[Back to Top](#-community-food-sharing-surplus-app)

</div>
