package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/keyvault/azsecrets"
)

func run(ctx context.Context) {
	// NOTE: intentionally to create a new credential each time to demo the token refresh
	cred, err := azidentity.NewWorkloadIdentityCredential(&azidentity.WorkloadIdentityCredentialOptions{})
	if err != nil {
		log.Fatal("failed to obtain a credential: ", err)
	}

	// Get Key Vault URL from environment variable
	keyVaultURL := os.Getenv("KEYVAULT_URL")
	if keyVaultURL == "" {
		log.Fatal("KEYVAULT_URL environment variable is not set")
	}

	// Get secret name from environment variable (default to "demo-secret")
	secretName := os.Getenv("SECRET_NAME")
	if secretName == "" {
		log.Fatal("SECRET_NAME environment variable is not set")
	}

	client, err := azsecrets.NewClient(keyVaultURL, cred, nil)
	if err != nil {
		log.Fatalf("Failed to create Key Vault client: %v", err)
	}

	resp, err := client.GetSecret(ctx, secretName, "", nil)
	if err != nil {
		log.Fatalf("Failed to get secret: %v", err)
	}

	log.Printf("Secret Value: %s\n", *resp.Value)
}

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	for {
		run(ctx)

		select {
		case <-ctx.Done():
			return
		default:
		}
		time.Sleep(5 * time.Second)
	}
}
