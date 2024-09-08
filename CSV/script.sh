#!/bin/bash

load_and_replace_delimeter() {
    file=$1
    del=$2
    
    sed "s/$del/,/g" "$file" > new_csv_file.csv
    echo "new_csv_file.csv"

    COL=$(head -n 1 "$CSV_FILE" | tr -cd ',' | wc -c)
    ROW=$( echo "$CSV_FILE" | wc -l)
}

display_menu() {
    echo "CSV Data Analysis"
    echo "--------------------------------------------------------------------"
    echo "1. Display row and column count"
    echo "2. Display unique values in a column"
    echo "3. Display column headers"
    echo "4. Display min and max values for numeric columns"
    echo "5. Display most frequent values for categorical columns"
    echo "6. Summary statistics for numeric columns"
    echo "7. Filter and extract"
    echo "8. Sort the CSV file"
    echo "9. Exit"
    echo -n "Please choose among these options: " 
}


save_analysis_result() {
    text=$1
    file_name=$2

    read -p "Do you want to save this analysis? (y/n): " save_choice
    if [[ $save_choice =~ ^[Yy]$ ]]; then
        echo -e "$text" > "$file_name"
        echo "Analysis saved to $file_name"
    fi

}

filter_and_extract() {
    echo "--------------------------------------------------------------------"
    echo "Choose a filter option:"
    echo "1. Extract data by range from a specific column"
    echo "2. Search by name"
    echo "3. Search by gender"
    read -p "Enter your choice: " filter_choice

    case $filter_choice in
        1)
            read -p "Enter the column number you want to extract data from: " column_number

            local COL=$(head -n 1 "$CSV_FILE" | tr -cd ',' | wc -c)
            COL=$((COL + 1))  

            while [[ ! "$column_number" =~ ^[0-9]+$ ]] || ((column_number < 1 || column_number > COL)); do
                echo -n "Invalid column number, try again: "
                read -r column_number
            done

            local values=$(cut -d ',' -f $column_number "$CSV_FILE" | tail -n +2 | sort)
            IFS=',' read -r -a headers < "$CSV_FILE"

            if [[ ! "$values" =~ [0-9] ]]; then
                echo "Column $column_number (${headers[column_number-1]}) does not contain numerical values."
                return 1
            fi

            read -p "Enter the lower bound: " lower_bound
            read -p "Enter the upper bound: " upper_bound

            result="Results:\n"
            result+="--------------------------------------------------------------------\n"
    
            while IFS=',' read -ra row; do
                for i in "${!row[@]}"; do
                    if (( i + 1 == column_number )); then
                        value="${row[$i]}"

                        if (( value >= lower_bound && value <= upper_bound )); then
                            result+="${row[*]}\n"
                        fi
                    fi
                done
            done < "$CSV_FILE"
            result+="--------------------------------------------------------------------"
            echo -e "$result"
            ;;
            
        
        2)
            read -p "Enter the name you want to search for: " name
            result="Results:\n"
            result+="--------------------------------------------------------------------\n"
    
            while IFS=',' read -ra row; do
                if [[ "${row[0]}" == "$name" ]]; then
                    result+="${row[*]}\n"
                fi
            done < <(tail -n +2 "$CSV_FILE")
            result+="--------------------------------------------------------------------"
            echo -e "$result"
            ;;
        
        3)
            read -p "Enter the gender you want to search for (M/F): " gender
            result="Results:\n"
            result+="--------------------------------------------------------------------\n"
    
            while IFS=',' read -ra row; do
                if [[ "${row[3]}" == "$gender" ]]; then
                    result+="${row[*]}\n"
                fi
            done < <(tail -n +2 "$CSV_FILE")
            result+="--------------------------------------------------------------------"

            echo -e "$result"
    
            ;;
        
        *)
            echo "Invalid choice!"
            ;;
    esac

    save_analysis_result "$result" "analysis_result(filter_and_extract).txt"
}

execute_user_choice() {
    read choice

    case $choice in
        1) display_row_col_cnt ;;
        2) list_unique_values ;;  
        3) display_header_names ;;
        4) min_and_max_values ;;
        5) find_mode_in_column ;;
        6) calculate_summary_statistics ;;
        7) filter_and_extract ;;
        8) sort_csv_file ;;
        9)  
            echo "Exiting..."
            exit 0
            ;;
        *) 
            echo "Invalid choice" ;;
    esac

}


display_row_col_cnt() {
    echo "--------------------------------------------------------------------"
    # wc (word count) | -l (this option counts the number of rows)
    row_cnt=$(wc -l < "$CSV_FILE")
    
    # head -n 1 outputs the first line of the file
    # tr deletes character from an input. -c it complements all the character set except "," in this case
    # -d option it performs the delete operation
    # wc (word count), -c counts the number of characters in this case the commas
    col_cnt=$(head -n 1 "$CSV_FILE" | tr -cd ',' | wc -c)
    result="Number of rows: $row_cnt\nNumber of columns: $((col_cnt + 1)) "
    echo -e "$result"

    save_analysis_result "$result" "analysis_result(dislpay_row_col_cnt).txt"
}

list_unique_values() {
    echo "--------------------------------------------------------------------"
    local column_count=$(head -n 1 "$CSV_FILE" | tr -cd ',' | wc -c)
    column_count=$(( column_count + 1 ))
    
    read -p "Enter the column number you want to do opeartion on: " column_number
    
    while ((column_number < 1 || column_number > column_count)); do
        echo -n "Invalid column number. Please choose a column between 1 and $column_count: "
        read -r column_number
    done

    local values=$(cut -d ',' -f $column_number "$CSV_FILE" | tail -n +2 | sort)
    IFS=',' read -r -a headers < "$CSV_FILE"

    if [[ ! "$values" =~ [0-9] ]]; then
        echo "Column $column_number (${headers[column_number-1]}) does not contain numerical values."
        return 0
    fi

    # cut cmd extracts columns from each line based on the delimiter (-d)
    # -f command specifies the column to extract
    # and outputs the values from the specified column

    # sort sorts them out but the -u option removes duplicates
    unique=$(tail -n +2 "$CSV_FILE" | cut -d ',' -f "$column_number" | sort -u)
    output=$(echo "$unique" | tr '\n' ' ')
    results="Unique values in column $column_number: $output"
    
    echo "$results"
    save_analysis_result "$results" "analysis_result(list_unique_values).txt"
}

display_header_names() {
    echo "--------------------------------------------------------------------"
    headers=$(head -n 1 "$CSV_FILE" | tr ',' ' ')
    result="Headers: $headers"
    echo "$result"

    save_analysis_result "$result" "analysis_result(display_header_names).txt"
}

min_and_max_values() {
    echo "--------------------------------------------------------------------"
    echo "This section returns the minimum and maximum value for all numerical headers."
    declare -A max_values 
    declare -A min_values 

    IFS=',' read -r -a headers < "$CSV_FILE"

    while IFS=',' read -ra row; do
        for i in "${!row[@]}"; do  

            if [[ ${row[$i]} =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                if [[ -z ${min_values[$i]} ]]; then
                    min_values[$i]=${row[$i]}
                    max_values[$i]=${row[$i]}
                fi

                if (( ${row[$i]} < ${min_values[$i]} )); then
                    min_values[$i]=${row[$i]}
                fi
                if (( ${row[$i]} > ${max_values[$i]} )); then
                    max_values[$i]=${row[$i]}
                fi
            fi
        done
    done < "$CSV_FILE"

    result=""
    for i in "${!min_values[@]}"; do
        result+="Column: ${headers[$i]} | Minimum value: ${min_values[$i]} | Maximum value: ${max_values[$i]}\n"
    done

    echo -e "$result"
    save_analysis_result "$result" "analysis_result(min_max_values).txt"

}

find_mode_in_column() {
    echo "--------------------------------------------------------------------"
    echo "This section returns the minimum and maximum value for all numerical headers."
    
    IFS=',' read -r -a headers < "$CSV_FILE"

    num_columns=$(head -n 1 "$CSV_FILE" | tr ',' '\n' | wc -l)
    
    results=""
    for ((i = 1; i <= num_columns; i++)); do
        if [[ $(cut -d ',' -f"$i" "$CSV_FILE" | grep -E '^[0-9]+$' ) ]]; then
            sorted_data=$(cut -d ',' -f "$i" "$CSV_FILE" | sort)
            counted_data=$(echo "$sorted_data" | uniq -c)

            max_count=$(echo "$counted_data" | awk '{print $1}' | sort -nr | head -1)

            modes=$(echo "$counted_data" | awk '{if ($1 == '"$max_count"') print $2}')
            output=$(echo "${modes[@]}" | tr '\n' ' ')
            echo 
            result+="Mode(s) of ${headers[$i]} : $output\n" 

        fi
        
    done 
    echo -e "$result" 

    save_analysis_result "$result" "analysis_result(find_mode_in_column).txt"
}

calculate_summary_statistics(){
    echo "--------------------------------------------------------------------"
    local column_count=$(head -n 1 "$CSV_FILE" | tr -cd ',' | wc -c)
    column_count=$((column_count + 1))

    read -p "Enter the column number you want to calculate statistics for: " selected_column

    while [[ ! "$selected_column" =~ ^[0-9]+$ ]] || ((selected_column < 1 || selected_column > column_count)); do
        echo -n "Invalid column number. Please choose a column between 1 and $column_count: "
        read -r selected_column
    done

    local values=$(cut -d ',' -f $selected_column "$CSV_FILE" | tail -n +2 | sort)
    IFS=',' read -r -a headers < "$CSV_FILE"

    if [[ ! "$values" =~ [0-9] ]]; then
        result="Column $selected_column (${headers[selected_column-1]}) does not contain numerical values."
        echo "$result"
        return 1
    fi

    result="Calculating statistics for column $selected_column:"

    echo "What Operation Would you Like to perform on the selected column:"
    echo "1. Calculate Mean Value"
    echo "2. Calculate Median Value"
    echo "3. Calculate Standard Deviation"
    read -p "Enter your choice: " calc_choice

    case $calc_choice in
        1)  
            local sum=0
            local count=0
            for value in $values; do
                ((count++))
                sum=$((sum + value))
            done
            local mean=$((sum / count))
            result+="\nMean: $mean"
            echo "Mean: $mean"
            ;;
        2)  
            local values_array=($values)
            local num_values=${#values_array[@]}
            local mid=$((num_values / 2))

            IFS=$'\n' sorted_values=($(sort -n <<<"${values_array[*]}"))
            # unset IFS

            if ((num_values % 2 == 0)); then
                median=$(( (${sorted_values[mid - 1]} + ${sorted_values[mid]}) / 2 ))
            else
                median=${sorted_values[mid]}
            fi

            result+="\nMedaian: $median"
            echo "Median: $median" ;;

        3)  
            local sum=0
            local count=0
            local mean=0
            for value in $values; do
                ((count++))
                sum=$((sum + value))
            done
            mean=$((sum / count))
            local variance=0
            for value in $values; do
                variance=$((variance + (value - mean) ** 2))
            done
            local std_dev=$(echo "sqrt($variance / $count)" | awk '{printf "%.2f", $1}')
            result+="Standard deviation: $std_dev"
            echo "Standard deviation: $std_dev"
            ;;
        *)  
            echo "Invalid Choice!"
            return 1
            ;;
    esac


    save_analysis_result "$result" "analysis_result(calculate_summary_statistics).txt"
}

sort_csv_file() {
    echo "--------------------------------------------------------------------"
    echo -n "Enter the column number to sort by: "
    read -r sort_col

    local col_count=$(head -n 1 "$CSV_FILE" | tr -cd ',' | wc -c)
    col_count=$((col_count + 1))

    while [[ ! "$sort_col" =~ ^[0-9]+$ ]] || ((sort_col < 1 || sort_col > col_count)); do
        echo -n "Invalid column number. Please choose a column between 1 and $col_count: "
        read -r sort_col
    done

    read -p "Do you want to sort in reverse order? (y/n): " reverse_order

    echo "Sorted results:"
    echo "--------------------------------------------------------------------"

    if [[ $reverse_order =~ ^[Yy]$ ]]; then
        result=$(sort -t ',' -k"$sort_col" -nr "$CSV_FILE")
    else
        result=$(sort -t ',' -k"$sort_col" -n "$CSV_FILE")
    fi

    echo -e "$result"

    save_analysis_result "$result" "analysis_result(sort_csv_file).txt"
}


# Main Section
echo -n "Enter the CSV file: "
read -r CSV_FILE
if [[ !(-e "$CSV_FILE") ]]; then
    echo "File does not exist."
    exit
fi

echo -n "Enter the delimeter (comma, semicolon, or a tab): "
read -r delimeter

CSV_FILE=$(load_and_replace_delimeter "$CSV_FILE" "$delimeter")

while true; do
    display_menu
    execute_user_choice
done