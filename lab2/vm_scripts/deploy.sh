#! /bin/bash
if [ $# -lt 1 ]; then
  echo "Usage: $0 CONFIG_FILE"
  exit 2
fi

az account show -o none

CONFIG_FILE="$1"

#resource group

RESOURCE_GROUP="$(jq -r '.resource_group' $CONFIG_FILE)"

echo $RESOURCE_GROUP

az group create --name $RESOURCE_GROUP --location uksouth

#network 
NETWORK_ADDRESS_PREFIX="$(jq -r '.network_address_prefix' $CONFIG_FILE)"

az network vnet create\
    --name VNet \
    --resource-group $RESOURCE_GROUP \
    --address-prefix $NETWORK_ADDRESS_PREFIX

#network security group

readarray -t NETWORK_SECURITY_GROUPS < <(jq -c '.network_security_group[]' "$CONFIG_FILE")

for NGS in ${NETWORK_SECURITY_GROUPS[@]}; do
    echo $NGS
    
    NGS_NAME="$(jq -r ".name" <<< $NGS)"
    echo $NGS_NAME

    az network nsg create \
        --name $NGS_NAME \
        --resource-group $RESOURCE_GROUP

    readarray -t RULES < <(jq -c '.rule[]' <<< $NGS)

    for RULE in "${RULES[@]}"; do
        echo $RULE

        RULE_NAME=$(jq -r ".name" <<< $RULE)
        RULE_PRIORITY=$(jq -r ".priority" <<< $RULE)
        RULE_SOURCE_ADDRESS_PREFIX=$(jq -r ".source_address_prefix" <<< $RULE)
        RULE_SOURCE_PORT_RANGE=$(jq -r ".source_port_range" <<< $RULE)
        RULE_DESTINATION_ADDRESS_PREFIX=$(jq -r ".destination_address_prefix" <<< $RULE)
        RULE_DESTINATION_PORT_RANGE=$(jq -r ".destination_port_range" <<< $RULE)


        az network nsg rule create \
            --name $RULE_NAME \
            --nsg-name $NGS_NAME \
            --priority $RULE_PRIORITY \
            --resource-group $RESOURCE_GROUP \
            --access Allow \
            --destination-address-prefixes "$RULE_DESTINATION_ADDRESS_PREFIX" \
            --destination-port-ranges "$RULE_DESTINATION_PORT_RANGE" \
            --protocol Tcp \
            --source-address-prefixes "$RULE_SOURCE_ADDRESS_PREFIX" \
            --source-port-ranges "$RULE_SOURCE_PORT_RANGE"
    done 

done

#subnet

readarray -t SUBNETS < <(jq -c '.subnet[]' "$CONFIG_FILE")
for SUBNET in ${SUBNETS[@]}; do
    echo $SUBNET

    SUBNET_NAME=$(jq -r ".name" <<< $SUBNET)
    SUBNET_ADDRESS_PREFIX=$(jq -r ".address_prefix" <<< $SUBNET)
    SUBNET_NSG=$(jq -r ".network_security_group" <<< $SUBNET)


    az network vnet subnet create \
        --name $SUBNET_NAME\
        --resource-group $RESOURCE_GROUP \
        --vnet-name VNet \
        --address-prefixes $SUBNET_ADDRESS_PREFIX \
        --network-security-group "$SUBNET_NSG"
done 

# public IP 
readarray -t PUBLIC_IPS < <(jq -c '.public_ip[]' "$CONFIG_FILE")

for PUBLIC_IP in "${PUBLIC_IPS[@]}"; do
    echo $PUBLIC_IP

    PUBLIC_IP_NAME=$(jq -r '.name' <<< $PUBLIC_IP)

    az network public-ip create \
        --resource-group $RESOURCE_GROUP \
        --name $PUBLIC_IP_NAME
done

readarray -t VIRTUAL_MACHINES < <(jq -c '.virtual_machine[]' "$CONFIG_FILE")

for VM in "${VIRTUAL_MACHINES[@]}"; do
    echo $VM

    VM_NAME=$(jq -r '.name' <<< $VM)
    VM_SUBNET=$(jq -r '.subnet' <<< $VM)
    VM_PRIVATE_IP_ADDRESS=$(jq -r '.private_ip_address' <<< $VM)
    VM_PUBLIC_IP_ADDRESS=$(jq -r '.public_ip_address' <<< $VM)

    az vm create \
        --resource-group $RESOURCE_GROUP \
        --vnet-name VNet \
        --name $VM_NAME \
        --subnet $VM_SUBNET \
        --nsg "" \
        --private-ip-address "$VM_PRIVATE_IP_ADDRESS" \
        --public-ip-address "$VM_PUBLIC_IP_ADDRESS" \
        --image Ubuntu2204 \
        --generate-ssh-keys

done
