
protocol="http"
organisation="LOG430-E26-VDEGRANDPRE"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --http)
            protocol="http"
            shift
            ;;
        --ssh)
            protocol="ssh"
            shift
            ;;
        -o|--organisation)
            organisation="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

DEFAULT_SERVICES=(
    svc-catalogue
    svc-clients
    svc-commandes
    svc-facturation
    svc-orchestration
    svc-lignes
    svc-audit
    svc-portability-hub
    test-charge
)

# If no services were specified, clone all of them.
if [[ $# -eq 0 ]]; then
    SERVICES=("${DEFAULT_SERVICES[@]}")
else
    SERVICES=("$@")
fi

for service in "${SERVICES[@]}"; do
    if [[ "$protocol" == "http" ]]; then
        repo_url="https://github.com/${organisation}/${service}.git"
    else
        repo_url="git@github.com:${organisation}/${service}.git"
    fi

    # echo "Cloning $repo_url"
    git clone "$repo_url"
done


for service in "${SERVICES[@]}"; do
    [[ "$service" == "svc-portability" ]] && continue

    if [[ -f "$service/.env.example" ]]; then
        cp "$service/.env.example" "$service/.env"
    fi
done
