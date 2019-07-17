#include "generator/regions/specs/belarus.hpp"

#include "generator/regions/country_specifier_builder.hpp"

namespace generator
{
namespace regions
{
namespace specs
{
REGISTER_COUNTRY_SPECIFIER(BelarusSpecifier);

PlaceLevel BelarusSpecifier::GetSpecificCountryLevel(Region const & region) const
{
  AdminLevel adminLevel = region.GetAdminLevel();
  switch (adminLevel)
  {
  case AdminLevel::Four: return PlaceLevel::Region;  // Oblasts (вобласьць / область)
  case AdminLevel::Six: return PlaceLevel::Subregion;  // Regions (раён / район)
  case AdminLevel::Eight:
    return PlaceLevel::Locality;  // Soviets of settlement (сельсавет / cельсовет)
  case AdminLevel::Nine: return PlaceLevel::Sublocality;  // Suburbs (раён гораду / район города)
  case AdminLevel::Ten:
    return PlaceLevel::Locality;  // Municipalities (населены пункт / населённый пункт)
  default: break;
  }

  return PlaceLevel::Unknown;
}
}  // namespace specs
}  // namespace regions
}  // namespace generator
