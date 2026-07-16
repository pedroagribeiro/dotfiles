def create_food_diaries_for_patient(email, food_diaries, filled)
  account = Account.find_by!(email: email)

  patient = account.patient

  food_diaries.times do |n|
    food_diary = FoodDiary.new do |food_diary|
      food_diary.patient       = patient
      food_diary.date          = Date.today - n.days
      food_diary.created_at    = Time.zone.now - n.days
      food_diary.updated_at    = Time.zone.now - n.days
      food_diary.created_by_id = CreatedBy::PATIENT
    end

    if filled
      as_planned_meal = FoodDiaryMeal.new do |as_planned_meal|
        as_planned_meal.food_diary = food_diary
        as_planned_meal.meal_type_id = MealType::BREAKFAST
        as_planned_meal.meal_wrapper_status_id = MealWrapperStatus::FOLLOWS_MEAL_PLAN

        food_diary.food_diary_meals << as_planned_meal
      end
    end

    food_diary.save!
  end
end

email        = ARGV[0]
food_diaries = ARGV[1].to_i
filled       = ARGV[2] == "true"

create_food_diaries_for_patient(email, food_diaries, filled)
