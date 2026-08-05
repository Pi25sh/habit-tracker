# Use an official Node runtime as a parent image, using Alpine for smaller attack surface
FROM node:18-alpine

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY backend/package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy the rest of the application code
COPY backend/ .

# Ensure the database directory exists and is writable
RUN mkdir -p /usr/src/app/data
RUN chown -R node:node /usr/src/app/data

# Switch to non-root user for security
USER node

# Expose port 3000
EXPOSE 3000

# Define environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Run the app
CMD ["node", "server.js"]
