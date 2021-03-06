Sequel.migration do
  change do
    create_table(:fachs) do
      String :type, :size=>255
      String :quality, :size=>255
      TrueClass :coloratura
      primary_key :id
    end
    
    create_table(:organizations) do
      String :name, :size=>255
      String :address_1, :size=>255
      String :address_2, :size=>255
      String :country, :size=>255
      String :city, :size=>255
      String :region, :size=>255
      String :postal_code, :size=>255
      String :website, :size=>255
      String :contact_name, :size=>255
      String :phone_1, :size=>255
      String :phone_2, :size=>255
      String :email_1, :size=>255
      String :email_2, :size=>255
      String :fax, :size=>255
      String :created_at, :size=>255
      String :updated_at, :size=>255
      primary_key :id
    end
    
    create_table(:programs) do
      Integer :organization_id
      String :type, :size=>255
      Integer :min_age
      Integer :max_age
      String :website, :size=>255
      String :contact_name, :size=>255
      String :contact_phone, :size=>255
      String :contact_email, :size=>255
      DateTime :created_at
      DateTime :updated_at
      String :name, :size=>255
      String :country, :size=>255
      String :region, :size=>255
      String :city, :size=>255
      
      primary_key :id
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
      String :username, :size=>255, :null=>false
      String :password, :size=>255, :null=>false
      String :email, :size=>255, :null=>false
      String :first_name, :size=>255
      String :last_name, :size=>255
      Date :birthdate
      String :city, :size=>255
      String :country, :size=>255
      String :fach, :size=>255
      TrueClass :admin, :default=>false
      DateTime :created_at
      DateTime :updated_at
      
      index [:email], :name=>:email, :unique=>true
      index [:username], :name=>:username, :unique=>true
    end
    
    create_table(:programs_users, :ignore_index_errors=>true) do
      foreign_key :program_id, :programs, :key=>[:id]
      foreign_key :user_id, :users, :key=>[:id]
      
      index [:program_id], :name=>:program_id
      index [:user_id], :name=>:user_id
    end
    
    create_table(:seasons, :ignore_index_errors=>true) do
      primary_key :id
      Date :start_date
      Date :end_date
      Date :early_bird_deadline
      Date :priority_deadline
      Date :final_deadline
      Float :payments
      Float :program_fees
      Float :peripheral_fees
      Float :application_fee
      foreign_key :program_id, :programs, :key=>[:id]
      DateTime :created_at
      DateTime :updated_at
      TrueClass :stale
      
      index [:program_id], :name=>:program_id
    end
    
    create_table(:task_lists, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :user_id, :users, :key=>[:id]
      String :title, :size=>255
      DateTime :created_at
      DateTime :updated_at
      
      index [:user_id], :name=>:user_id
    end
    
    create_table(:auditions, :ignore_index_errors=>true) do
      primary_key :id
      String :country, :size=>255
      String :region, :size=>255
      String :city, :size=>255
      Date :date
      DateTime :created_at
      DateTime :updated_at
      Date :deadline
      TrueClass :pianist_provided
      TrueClass :can_bring_own_pianist
      Float :pianist_fee
      Float :fee
      foreign_key :season_id, :seasons, :key=>[:id]
      
      index [:season_id], :name=>:season_id
    end
    
    create_table(:listings, :ignore_index_errors=>true) do
      primary_key :id
      String :title, :size=>255
      DateTime :created_at
      DateTime :updated_at
      foreign_key :season_id, :seasons, :key=>[:id]
      
      index [:season_id], :name=>:season_id
    end
    
    create_table(:tasks, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :task_list_id, :task_lists, :key=>[:id]
      String :title, :size=>255
      String :status, :default=>"new", :size=>255
      String :priority, :default=>"normal", :size=>255
      DateTime :deadline
      String :description, :text=>true
      Integer :owner_id
      DateTime :created_at
      DateTime :updated_at
      TrueClass :backlog
      Integer :position
      
      index [:task_list_id], :name=>:task_list_id
    end
  end
end
