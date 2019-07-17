#include "generator/regions/specs/georgia.hpp"

#include "generator/regions/country_specifier_builder.hpp"

namespace generator
{
namespace regions
{
namespace specs
{
REGISTER_COUNTRY_SPECIFIER(GeorgiaSpecifier);

PlaceLevel GeorgiaSpecifier::GetSpecificCountryLevel(Region const & region) const
{
  AdminLevel adminLevel = region.GetAdminLevel();
  switch (adminLevel)
  {
  case AdminLevel::Four:
    return PlaceLevel::Region;  // regions (მხარე) including the Ajaran Autonomous Republic
  case AdminLevel::Six: return PlaceLevel::Subregion;  // districts (რაიონი)
  default: break;
  }

  return PlaceLevel::Unknown;
}
}  // namespace specs
}  // namespace regions
}  // namespace generator
