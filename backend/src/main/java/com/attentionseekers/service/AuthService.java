package com.attentionseekers.service;

import com.attentionseekers.dto.RegisterRequest;
import com.attentionseekers.dto.RegisterResponse;
import com.attentionseekers.model.User;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class AuthService {

    private static final String DATA_DIR = "./backend/src/data/database";
    private static final String USER_FILE = DATA_DIR + "/user.json";
    private final ObjectMapper objectMapper;

    public AuthService() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
        initializeDataDirectory();
    }

    private void initializeDataDirectory() {
        try {
            Path dataPath = Paths.get(DATA_DIR);
            if (!Files.exists(dataPath)) {
                Files.createDirectories(dataPath);
            }

            File userFile = new File(USER_FILE);
            if (!userFile.exists()) {
                objectMapper.writeValue(userFile, new ArrayList<User>());
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to initialize data directory", e);
        }
    }

    private List<User> readUsers() throws IOException {
        File file = new File(USER_FILE);
        if (!file.exists() || file.length() == 0) {
            return new ArrayList<>();
        }
        return objectMapper.readValue(file, new TypeReference<List<User>>() {});
    }

    private void writeUsers(List<User> users) throws IOException {
        objectMapper.writerWithDefaultPrettyPrinter()
                .writeValue(new File(USER_FILE), users);
    }

    public RegisterResponse registerUser(RegisterRequest request) throws Exception {
        List<User> users = readUsers();

        // Check if email already exists
        boolean emailExists = users.stream()
                .anyMatch(u -> u.getEmail().equalsIgnoreCase(request.getEmail()));
        if (emailExists) {
            throw new Exception("Email already registered");
        }

        // Check if phone number already exists
        boolean phoneExists = users.stream()
                .anyMatch(u -> u.getPhoneNumber().equals(request.getPhoneNumber()));
        if (phoneExists) {
            throw new Exception("Phone number already registered");
        }

        // Check if license number already exists
        boolean licenseExists = users.stream()
                .anyMatch(u -> u.getLicenseNumber().equals(request.getLicenseNumber()));
        if (licenseExists) {
            throw new Exception("License number already registered");
        }

        // Create new user
        User newUser = new User();
        newUser.setId(UUID.randomUUID().toString());
        newUser.setFullName(request.getFullName());
        newUser.setEmail(request.getEmail());
        newUser.setPhoneNumber(request.getPhoneNumber());
        newUser.setPassword(hashPassword(request.getPassword())); // Hash password
        newUser.setVehicleType(request.getVehicleType());
        newUser.setLicenseNumber(request.getLicenseNumber());
        newUser.setRating(5.0);
        newUser.setTotalTrips(0);
        newUser.setTotalEarnings(0.0);
        newUser.setJoinedDate(LocalDateTime.now());

        users.add(newUser);
        writeUsers(users);

        return mapToResponse(newUser);
    }

    public RegisterResponse loginUser(String email, String password) throws Exception {
        List<User> users = readUsers();

        User user = users.stream()
                .filter(u -> u.getEmail().equalsIgnoreCase(email))
                .findFirst()
                .orElseThrow(() -> new Exception("Invalid email or password"));

        if (!verifyPassword(password, user.getPassword())) {
            throw new Exception("Invalid email or password");
        }

        return mapToResponse(user);
    }

    private String hashPassword(String password) {
        return String.valueOf(password.hashCode());
    }

    private boolean verifyPassword(String plainPassword, String hashedPassword) {
        return hashPassword(plainPassword).equals(hashedPassword);
    }

    private RegisterResponse mapToResponse(User user) {
        RegisterResponse response = new RegisterResponse();
        response.setId(user.getId());
        response.setFullName(user.getFullName());
        response.setEmail(user.getEmail());
        response.setPhoneNumber(user.getPhoneNumber());
        response.setVehicleType(user.getVehicleType());
        response.setLicenseNumber(user.getLicenseNumber());
        response.setRating(user.getRating());
        response.setTotalTrips(user.getTotalTrips());
        response.setTotalEarnings(user.getTotalEarnings());
        response.setJoinedDate(user.getJoinedDate().toString());
        return response;
    }
}