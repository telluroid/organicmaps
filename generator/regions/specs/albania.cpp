#include "generator/regions/specs/albania.hpp"

#include "generator/regions/country_specifier_builder.hpp"

namespace generator
{
namespace regions
{
namespace specs
{
REGISTER_COUNTRY_SPECIFIER(AlbaniaSpecifier);

PlaceLevel AlbaniaSpecifier::GetSpecificCountryLevel(Region const & region) const
{
  AdminLevel adminLevel = region.GetAdminLevel();
  switch (adminLevel)
  {
  case AdminLevel::Six: return PlaceLevel::Region;       // counties
  case AdminLevel::Seven: return PlaceLevel::Subregion;  // districts
  case AdminLevel::Nine: return PlaceLevel::Suburb;      // Neighborhoods of Tirana
  default: break;
  }

  return PlaceLevel::Unknown;
}
}  // namespace specs
}  // namespace regions
}  // namespace generator
