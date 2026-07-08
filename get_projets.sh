git clone https://github.com/LOG430-E26-VDEGRANDPRE/svc-orchestration.git
git clone https://github.com/LOG430-E26-VDEGRANDPRE/svc-commandes.git
git clone https://github.com/LOG430-E26-VDEGRANDPRE/svc-lignes.git
git clone https://github.com/LOG430-E26-VDEGRANDPRE/svc-catalogue.git
git clone https://github.com/LOG430-E26-VDEGRANDPRE/svc-clients.git
git clone https://github.com/LOG430-E26-VDEGRANDPRE/svc-facturation.git
git clone https://github.com/LOG430-E26-VDEGRANDPRE/svc-audit.git
git clone https://github.com/LOG430-E26-VDEGRANDPRE/test-charge.git

SERVICES=("svc-catalogue" "svc-clients" "svc-commandes" "svc-facturation" "svc-orchestration" "svc-lignes")

for service in "${SERVICES[@]}"; do
    cd $service
    cp .env.example .env
    cd ..
done