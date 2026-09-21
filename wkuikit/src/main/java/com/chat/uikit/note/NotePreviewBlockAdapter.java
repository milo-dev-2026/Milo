package com.chat.uikit.note;

import android.graphics.drawable.Drawable;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.DataSource;
import com.bumptech.glide.load.engine.GlideException;
import com.bumptech.glide.request.RequestListener;
import com.bumptech.glide.request.target.Target;
import com.chat.base.config.WKApiConfig;
import com.chat.uikit.R;

import java.io.File;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 笔记预览块适配器（只读展示，支持标题/文字/图片/视频/位置）
 * 参考utalk实现：图片按真实宽高比自适应显示
 */
public class NotePreviewBlockAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private List<NoteBlock> blockList;
    private OnBlockClickListener listener;

    public interface OnBlockClickListener {
        void onImageClick(String imageShowUrl);
        void onVideoClick(String videoPath, String videoCover);
        void onLocationClick(NoteBlock block);
    }

    public void setOnBlockClickListener(OnBlockClickListener listener) {
        this.listener = listener;
    }

    public NotePreviewBlockAdapter(List<NoteBlock> blockList) {
        this.blockList = blockList;
    }

    @Override
    public int getItemViewType(int position) {
        return blockList.get(position).type;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        if (viewType == NoteBlock.TYPE_TITLE) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_note_block_title_preview, parent, false);
            return new TitleViewHolder(view);
        } else if (viewType == NoteBlock.TYPE_TEXT) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_note_block_text_preview, parent, false);
            return new TextViewHolder(view);
        } else if (viewType == NoteBlock.TYPE_IMAGE) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_note_block_image_preview, parent, false);
            return new ImageViewHolder(view);
        } else if (viewType == NoteBlock.TYPE_VIDEO) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_note_block_video_preview, parent, false);
            return new VideoViewHolder(view);
        } else if (viewType == NoteBlock.TYPE_LOCATION) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_note_block_location, parent, false);
            return new LocationViewHolder(view);
        }
        return new RecyclerView.ViewHolder(new View(parent.getContext())) {};
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        NoteBlock block = blockList.get(position);
        int type = getItemViewType(position);

        if (type == NoteBlock.TYPE_TITLE && holder instanceof TitleViewHolder) {
            TitleViewHolder vh = (TitleViewHolder) holder;
            vh.titleTv.setText(block.content != null ? block.content : "");
        } else if (type == NoteBlock.TYPE_TEXT && holder instanceof TextViewHolder) {
            TextViewHolder vh = (TextViewHolder) holder;
            vh.contentTv.setText(block.content != null ? block.content : "");
        } else if (type == NoteBlock.TYPE_IMAGE && holder instanceof ImageViewHolder) {
            ImageViewHolder vh = (ImageViewHolder) holder;
            if (!TextUtils.isEmpty(block.imagePath)) {
                vh.imageView.setVisibility(View.VISIBLE);
                // 统一处理本地路径、content URI和网络URL
                final String showUrl = getImageShowUrl(block.imagePath);
                // 参考utalk：图片加载完成后按真实宽高比调整高度
                loadImageWithAspectRatio(vh.imageView, showUrl);
                vh.itemView.setOnClickListener(v -> {
                    // 传递转换后的可加载URL，确保点击放大时能正确显示
                    if (listener != null) listener.onImageClick(showUrl);
                });
            } else {
                vh.imageView.setVisibility(View.GONE);
                vh.itemView.setOnClickListener(null);
            }
        } else if (type == NoteBlock.TYPE_VIDEO && holder instanceof VideoViewHolder) {
            VideoViewHolder vh = (VideoViewHolder) holder;
            if (!TextUtils.isEmpty(block.videoCover)) {
                vh.coverIv.setVisibility(View.VISIBLE);
                // 统一处理本地路径、content URI和网络URL
                final String showUrl = getImageShowUrl(block.videoCover);
                loadImageWithAspectRatio(vh.coverIv, showUrl);
                vh.itemView.setOnClickListener(v -> {
                    if (listener != null) listener.onVideoClick(block.videoPath, block.videoCover);
                });
            } else {
                vh.coverIv.setVisibility(View.GONE);
                vh.itemView.setOnClickListener(null);
            }
        } else if (type == NoteBlock.TYPE_LOCATION && holder instanceof LocationViewHolder) {
            LocationViewHolder vh = (LocationViewHolder) holder;
            vh.nameTv.setText(block.locationName != null ? block.locationName : "");
            vh.addressTv.setText(block.locationAddress != null ? block.locationAddress : "");
            vh.itemView.setOnClickListener(v -> {
                if (listener != null) listener.onLocationClick(block);
            });
        }
    }

    /**
     * 加载图片并按真实宽高比调整ImageView高度
     * 参考utalk NotePreviewAdapter 的实现：
     * height = imageHeight * (可用宽度) / imageWidth
     */
    private void loadImageWithAspectRatio(final ImageView imageView, String url) {
        if (TextUtils.isEmpty(url)) {
            imageView.setVisibility(View.GONE);
            return;
        }
        imageView.setVisibility(View.VISIBLE);
        Glide.with(imageView.getContext())
                .load(url)
                .listener(new RequestListener<Drawable>() {
                    @Override
                    public boolean onLoadFailed(@Nullable GlideException e, Object model,
                                                Target<Drawable> target, boolean isFirstResource) {
                        // 加载失败时不调整大小，保持默认
                        return false;
                    }

                    @Override
                    public boolean onResourceReady(Drawable resource, Object model,
                                                   Target<Drawable> target, DataSource dataSource,
                                                   boolean isFirstResource) {
                        // 图片加载成功后，按真实宽高比调整ImageView高度
                        int imgWidth = resource.getIntrinsicWidth();
                        int imgHeight = resource.getIntrinsicHeight();
                        if (imgWidth > 0 && imgHeight > 0) {
                            ViewGroup.LayoutParams lp = imageView.getLayoutParams();
                            // 可用宽度 = ImageView的测量宽度（match_parent时等于父容器宽度）
                            int availableWidth = imageView.getWidth();
                            if (availableWidth <= 0) {
                                // 如果还没测量，用父容器宽度估算（减去padding）
                                if (imageView.getParent() instanceof View) {
                                    availableWidth = ((View) imageView.getParent()).getWidth()
                                            - ((View) imageView.getParent()).getPaddingLeft()
                                            - ((View) imageView.getParent()).getPaddingRight();
                                }
                            }
                            if (availableWidth > 0) {
                                // 按比例计算高度：高度 = 图片高度 * 可用宽度 / 图片宽度
                                lp.height = (int) ((imgHeight * (float) availableWidth) / imgWidth);
                                imageView.setLayoutParams(lp);
                            }
                        }
                        return false;
                    }
                })
                .into(imageView);
    }

    @Override
    public int getItemCount() {
        return blockList.size();
    }

    /**
     * 将图片路径转换为可加载的URL
     * - 网络URL（http/https）：直接返回
     * - 本地绝对路径且文件存在：直接返回
     * - content URI：直接返回
     * - 相对路径：通过WKApiConfig.getShowUrl转换
     */
    public String getImageShowUrl(String imagePath) {
        if (TextUtils.isEmpty(imagePath)) return "";

        String lower = imagePath.toLowerCase();
        // 已经是完整的网络URL
        if (lower.startsWith("http://") || lower.startsWith("https://")) {
            return imagePath;
        }

        // 本地绝对路径且文件存在
        if (imagePath.startsWith("/") && !imagePath.startsWith("//") && imagePath.contains(".")) {
            File file = new File(imagePath);
            if (file.exists() && file.length() > 0) {
                return imagePath;
            }
        }

        // content URI 类型（Android 10+ 分区存储）
        if (imagePath.startsWith("content://")) {
            return imagePath;
        }

        // 相对路径：通过 getShowUrl 转换为完整可访问URL
        return WKApiConfig.getShowUrl(imagePath.replace("\\/", "/"));
    }

    static class TitleViewHolder extends RecyclerView.ViewHolder {
        TextView titleTv;
        TitleViewHolder(View itemView) {
            super(itemView);
            titleTv = itemView.findViewById(R.id.titleTv);
        }
    }

    static class TextViewHolder extends RecyclerView.ViewHolder {
        TextView contentTv;
        TextViewHolder(View itemView) {
            super(itemView);
            contentTv = itemView.findViewById(R.id.contentTv);
        }
    }

    static class ImageViewHolder extends RecyclerView.ViewHolder {
        ImageView imageView;
        ImageViewHolder(View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.imageIv);
        }
    }

    static class VideoViewHolder extends RecyclerView.ViewHolder {
        ImageView coverIv;
        VideoViewHolder(View itemView) {
            super(itemView);
            coverIv = itemView.findViewById(R.id.coverIv);
        }
    }

    static class LocationViewHolder extends RecyclerView.ViewHolder {
        TextView nameTv;
        TextView addressTv;
        View deleteBtn;
        LocationViewHolder(View itemView) {
            super(itemView);
            nameTv = itemView.findViewById(R.id.tvLocation);
            addressTv = itemView.findViewById(R.id.tvLocationDetail);
            deleteBtn = itemView.findViewById(R.id.ivDelete);
            if (deleteBtn != null) {
                deleteBtn.setVisibility(View.GONE);
            }
        }
    }
}
