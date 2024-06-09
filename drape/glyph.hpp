#pragma once

#include "base/assert.hpp"
#include "base/buffer_vector.hpp"
#include "base/shared_buffer_manager.hpp"

namespace dp
{
struct GlyphImage
{
  ~GlyphImage()
  {
    ASSERT_NOT_EQUAL(m_data.use_count(), 1, ("Probably you forgot to call Destroy()"));
  }

  // TODO(AB): Get rid of manual call to Destroy.
  void Destroy()
  {
    if (m_data != nullptr)
    {
      SharedBufferManager::instance().freeSharedBuffer(m_data->size(), m_data);
      m_data = nullptr;
    }
  }

  uint32_t m_width;
  uint32_t m_height;

  SharedBufferManager::shared_buffer_ptr_t m_data;
};

using TGlyph = std::pair<int16_t /* fontIndex */, uint16_t /* glyphId */>;
// TODO(AB): Measure if 32 is the best value here.
using TGlyphs = buffer_vector<TGlyph, 32>;

struct Glyph
{
  Glyph(GlyphImage && image, int16_t fontIndex, uint16_t glyphId)
  : m_image(image), m_fontIndex(fontIndex), m_glyphId(glyphId)
  {}

  GlyphImage m_image;
  int16_t m_fontIndex;
  uint16_t m_glyphId;
};
}  // namespace dp

