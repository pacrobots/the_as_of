# frozen_string_literal: true

class WelcomePanel < Lightyear::MSV::Panel
  goal :orient
  subscribes :intent
  speaks :welcome_card

  strategy :default do |_model, _situation|
    [{ component: :welcome_card,
       props: { title: "as_of — the workshop scaffold",
                body: "A placeholder panel: replace me with your app's first real surface. " \
                      "The contract is structured surfaces, not pixels — any client renders it." } }]
  end
end
