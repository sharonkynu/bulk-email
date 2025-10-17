#!/bin/bash

API_KEY="<API-KEY>"
DOMAIN="support.kynu.com"
FROM_EMAIL="support@kynu.com"
SUBJECT="Light up your Diwali with Bringgg & Earn Rewards! 🎁"
HTML_FILE="/home/sharon/Downloads/Diwali_wishes.html"
CSV_FILE="/home/sharon/Downloads/Bringgg_users_List_2025-10-15.csv"

BATCH_SIZE=600
WAIT_TIME=600  # 10 minutes

count=0
emails=()


while IFS= read -r line || [[ -n "$line" ]]; do
    email=$(echo "$line" | tr -d '\r' | xargs)
    [[ -z "$email" ]] && continue 
    emails+=("$email")
done < <(grep -v '^\s*$' "$CSV_FILE")

total=${#emails[@]}
echo " Starting bulk email sending with batches of $BATCH_SIZE (waiting $WAIT_TIME seconds between batches)..."
echo "Total emails to send: $total"

if (( total == 0 )); then
    echo "No emails found. Exiting."
    exit 1
fi


for ((i=0; i<total; i+=BATCH_SIZE)); do
    batch_emails=("${emails[@]:i:BATCH_SIZE}")
    bcc_list=$(IFS=','; echo "${batch_emails[*]}")

    batch_number=$((i / BATCH_SIZE + 1))
    echo "Sending batch $batch_number with ${#batch_emails[@]} recipients..."

    response=$(curl -s --location "https://api.mailgun.net/v3/${DOMAIN}/messages" \
        --user "api:${API_KEY}" \
        --form "from=${FROM_EMAIL}" \
        --form "to=${FROM_EMAIL}" \
        --form "subject=${SUBJECT}" \
        --form "html=@${HTML_FILE}" \
        --form "bcc=${bcc_list}")

    if [[ $? -eq 0 ]]; then
        count=$((count + ${#batch_emails[@]}))
        echo "Batch $batch_number completed: $count emails sent so far."
    else
        echo "Error sending batch $batch_number. Response: $response"
    fi

    if (( i + BATCH_SIZE < total )); then
        echo "Waiting $WAIT_TIME seconds before next batch..."
        sleep $WAIT_TIME
    fi
done

echo "All $count emails sent successfully!"

