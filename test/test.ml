open Core
open Travelguide

let restaurant_no_award_html =
  {|
<script type="application/ld+json">{"@context":"http://schema.org","address":{"@type":"PostalAddress","streetAddress":"Narva mnt. 92","addressLocality":"Tallinn","postalCode":"10127","addressCountry":"EST","addressRegion":"Harju"},"name":"Mon Repos","image":"https://axwwgrkdco.cloudimg.io/v7/__gmpics__/a1de5eb0d2274a06bc453f37348ee705?width=1000","@type":"Restaurant","review":{"@type":"Review","datePublished":"2022-05-25T11:13","name":"Mon Repos","description":"This former imperial summer residence overlooking Kadriorg Park comes with a charming interior which blends original stained glass and panelled ceilings with sleek, modern furnishings. Colourfully...","author":{"@type":"Person","name":"Michelin Inspector"}},"telephone":"+372 507 0273","knowsLanguage":"en-EE","priceRange":"60EUR","acceptsReservations":"No","servesCuisine":"Modern Cuisine","url":"https://guide.michelin.com/en/harju/tallinn/restaurant/mon-repos","currenciesAccepted":"EUR","paymentAccepted":"Credit card / Debit card accepted, Mastercard credit card, Visa credit card","brand":"MICHELIN Guide","hasDriveThroughService":"False","latitude":59.4409706,"longitude":24.7868407,"hasMap":"https://www.google.com/maps/search/?api=1&query=59.4409706%2C24.7868407"}</script>
<div class="typeahead__item typeahead__group-city-guides">
    <a href="{{url}}">
        <div class="typeahead">
            <div class="typeahead__item-title-container">
                <h6 class="typeahead__item-title clamp-1"
                    style="overflow: hidden; text-overflow: ellipsis; -webkit-box-orient: vertical; display: -webkit-box; -webkit-line-clamp: 1;">
                    <i class="fa-michelin typeahead__item-distinction notranslate"></i>{{{label}}}
                    <div class="typeahead__item-sub-title-container">
                        <div class="typeahead__item-sub-title">
                        </div>
                    </div>
                </h6>
            </div>
        </div>
    </a>
</div>
|}

let%test_unit "Restaurant Without Award" =
  let parsed_restaurant = Michelin.parse_restaurant restaurant_no_award_html in
  [%test_eq: string] parsed_restaurant.id "Mon Repos"

let restaurant_one_star_html =
  {|
<script type="application/ld+json">{"@context":"http://schema.org","address":{"@type":"PostalAddress","streetAddress":"Staapli 4, Port Noblessner","addressLocality":"Tallinn","postalCode":"10415","addressCountry":"EST","addressRegion":"Harju"},"name":"180\u00b0 by Matthias Diether","image":"https://axwwgrkdco.cloudimg.io/v7/__gmpics__/3a185f57cd21404a8538497c0f660813?width=1000","@type":"Restaurant","review":{"@type":"Review","datePublished":"2022-05-25T11:13","name":"180\u00b0 by Matthias Diether","description":"Sitting within a modern harbour development a couple of miles outside the city centre is this stylish restaurant named after the 180\u00b0 view from its U-shaped open kitchen; sit here for a ringside ...","author":{"@type":"Person","name":"Michelin Inspector"}},"telephone":"+372 661 0180","knowsLanguage":"en-EE","priceRange":"119EUR - 139EUR","acceptsReservations":"No","servesCuisine":"Creative","url":"https://guide.michelin.com/en/harju/tallinn/restaurant/180%C2%B0-by-matthias-diether","starRating":"One MICHELIN Star: High quality cooking, worth a stop!","currenciesAccepted":"EUR","paymentAccepted":"Credit card / Debit card accepted, Mastercard credit card, Visa credit card","award":"One MICHELIN Star: High quality cooking, worth a stop!","brand":"MICHELIN Guide","hasDriveThroughService":"False","latitude":59.4520878,"longitude":24.7284995,"hasMap":"https://www.google.com/maps/search/?api=1&query=59.4520878%2C24.7284995"}</script>
<div class="typeahead__item typeahead__group-city-guides">
    <a href="{{url}}">
        <div class="typeahead">
            <div class="typeahead__item-title-container">
                <h6 class="typeahead__item-title clamp-1"
                    style="overflow: hidden; text-overflow: ellipsis; -webkit-box-orient: vertical; display: -webkit-box; -webkit-line-clamp: 1;">
                    <i class="fa-michelin typeahead__item-distinction notranslate"></i>{{{label}}}
                    <div class="typeahead__item-sub-title-container">
                        <div class="typeahead__item-sub-title">
                        </div>
                    </div>
                </h6>
            </div>
        </div>
    </a>
</div>
|}

let%test_unit "Restaurant With One Star Award" =
  let parsed_restaurant = Michelin.parse_restaurant restaurant_one_star_html in
  [%test_eq: string] parsed_restaurant.id "180° by Matthias Diether"
