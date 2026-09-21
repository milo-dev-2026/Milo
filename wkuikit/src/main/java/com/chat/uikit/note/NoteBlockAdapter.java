package com.chat.uikit.note;

import android.net.Uri;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.chat.uikit.R;

import java.util.List;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

/**
 * 笔记块列表Adapter
 */
public class NoteBlockAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private List<NoteBlock> blockList;
    private OnBlockDeleteListener deleteListener;
    private OnBlockClickListener clickListener;

    public interface OnBlockDeleteListener {
        void onDelete(int position);
    }

    public interface OnBlockClickListener {
        void onBlockClick(int position, NoteBlock block);
    }

    public void setOnBlockDeleteListener(OnBlockDeleteListener listener) {
        this.deleteListener = listener;
    }

    public void setOnBlockClickListener(OnBlockClickListener listener) {
        this.clickListener = listener;
    }

    public NoteBlockAdapter(List<NoteBlock> blockList) {
        this.blockList = blockList;
    }

    @Override
    public int getItemViewType(int position) {
        return blockList.get(position).type;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        LayoutInflater inflater = LayoutInflater.from(parent.getContext());
        switch (viewType) {
            case NoteBlock.TYPE_TITLE:
                return new TitleViewHolder(inflater.inflate(R.layout.item_note_block_title, parent, false));
            case NoteBlock.TYPE_TEXT:
                return new TextViewHolder(inflater.inflate(R.layout.item_note_block_text, parent, false));
            case NoteBlock.TYPE_IMAGE:
                return new ImageViewHolder(inflater.inflate(R.layout.item_note_block_image, parent, false));
            case NoteBlock.TYPE_VIDEO:
                return new VideoViewHolder(inflater.inflate(R.layout.item_note_block_video, parent, false));
            case NoteBlock.TYPE_LOCATION:
                return new LocationViewHolder(inflater.inflate(R.layout.item_note_block_location, parent, false));
            default:
                return new TextViewHolder(inflater.inflate(R.layout.item_note_block_text, parent, false));
        }
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        NoteBlock block = blockList.get(position);
        switch (block.type) {
            case NoteBlock.TYPE_TITLE:
                ((TitleViewHolder) holder).bind(block);
                break;
            case NoteBlock.TYPE_TEXT:
                ((TextViewHolder) holder).bind(block);
                break;
            case NoteBlock.TYPE_IMAGE:
                ((ImageViewHolder) holder).bind(block);
                break;
            case NoteBlock.TYPE_VIDEO:
                ((VideoViewHolder) holder).bind(block);
                break;
            case NoteBlock.TYPE_LOCATION:
                ((LocationViewHolder) holder).bind(block);
                break;
        }
    }

    @Override
    public int getItemCount() {
        return blockList.size();
    }

    // 标题ViewHolder
    public class TitleViewHolder extends RecyclerView.ViewHolder {
        public EditText etTitle;
        ImageView ivDelete;
        NoteBlock currentBlock;

        TitleViewHolder(View itemView) {
            super(itemView);
            etTitle = itemView.findViewById(R.id.etTitle);
            ivDelete = itemView.findViewById(R.id.ivDelete);

            // TextWatcher 只在构造时添加一次
            etTitle.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {}

                @Override
                public void afterTextChanged(Editable s) {
                    if (currentBlock != null) {
                        currentBlock.content = s != null ? s.toString() : "";
                    }
                }
            });

            ivDelete.setOnClickListener(v -> {
                int pos = getAdapterPosition();
                if (deleteListener != null && pos != RecyclerView.NO_POSITION
                        && pos >= 0 && pos < blockList.size()) {
                    deleteListener.onDelete(pos);
                }
            });
        }

        void bind(NoteBlock block) {
            this.currentBlock = block;
            // 避免 TextWatcher 回调影响，先移除再设置
            etTextSetText(etTitle, block.content);
        }
    }

    // 文字ViewHolder
    public class TextViewHolder extends RecyclerView.ViewHolder {
        public EditText etText;
        ImageView ivDelete;
        NoteBlock currentBlock;

        TextViewHolder(View itemView) {
            super(itemView);
            etText = itemView.findViewById(R.id.etText);
            ivDelete = itemView.findViewById(R.id.ivDelete);

            // TextWatcher 只在构造时添加一次
            etText.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {}

                @Override
                public void afterTextChanged(Editable s) {
                    if (currentBlock != null) {
                        currentBlock.content = s != null ? s.toString() : "";
                    }
                }
            });

            ivDelete.setOnClickListener(v -> {
                int pos = getAdapterPosition();
                if (deleteListener != null && pos != RecyclerView.NO_POSITION
                        && pos >= 0 && pos < blockList.size()) {
                    deleteListener.onDelete(pos);
                }
            });
        }

        void bind(NoteBlock block) {
            this.currentBlock = block;
            etTextSetText(etText, block.content);
        }
    }

    /**
     * 安全设置 EditText 文本，避免触发 TextWatcher 导致光标位置错乱
     */
    private void etTextSetText(EditText editText, String text) {
        CharSequence oldText = editText.getText();
        if (oldText == null && text == null) return;
        if (oldText != null && text != null && oldText.toString().equals(text)) return;
        editText.setText(text);
        // 光标移到末尾
        if (text != null) {
            editText.setSelection(text.length());
        }
    }

    // 图片ViewHolder
    class ImageViewHolder extends RecyclerView.ViewHolder {
        ImageView ivImage;
        ImageView ivDelete;

        ImageViewHolder(View itemView) {
            super(itemView);
            ivImage = itemView.findViewById(R.id.ivImage);
            ivDelete = itemView.findViewById(R.id.ivDelete);

            ivDelete.setOnClickListener(v -> {
                int pos = getAdapterPosition();
                if (deleteListener != null && pos != RecyclerView.NO_POSITION
                        && pos >= 0 && pos < blockList.size()) {
                    deleteListener.onDelete(pos);
                }
            });
        }

        void bind(NoteBlock block) {
            if (block.imagePath != null) {
                Glide.with(ivImage.getContext())
                        .load(block.imagePath)
                        .centerCrop()
                        .into(ivImage);
            }
            ivImage.setOnClickListener(v -> {
                int pos = getAdapterPosition();
                if (clickListener != null && pos != RecyclerView.NO_POSITION
                        && pos >= 0 && pos < blockList.size()) {
                    clickListener.onBlockClick(pos, block);
                }
            });
        }
    }

    // 视频ViewHolder
    class VideoViewHolder extends RecyclerView.ViewHolder {
        ImageView ivVideo;
        ImageView ivDelete;
        ImageView ivPlay;

        VideoViewHolder(View itemView) {
            super(itemView);
            ivVideo = itemView.findViewById(R.id.ivVideo);
            ivDelete = itemView.findViewById(R.id.ivDelete);
            ivPlay = itemView.findViewById(R.id.ivPlay);

            ivDelete.setOnClickListener(v -> {
                int pos = getAdapterPosition();
                if (deleteListener != null && pos != RecyclerView.NO_POSITION
                        && pos >= 0 && pos < blockList.size()) {
                    deleteListener.onDelete(pos);
                }
            });
        }

        void bind(NoteBlock block) {
            if (block.videoCover != null) {
                Glide.with(ivVideo.getContext())
                        .load(block.videoCover)
                        .centerCrop()
                        .into(ivVideo);
            } else if (block.videoPath != null) {
                Glide.with(ivVideo.getContext())
                        .load(Uri.parse(block.videoPath))
                        .centerCrop()
                        .into(ivVideo);
            }
            itemView.setOnClickListener(v -> {
                int pos = getAdapterPosition();
                if (clickListener != null && pos != RecyclerView.NO_POSITION
                        && pos >= 0 && pos < blockList.size()) {
                    clickListener.onBlockClick(pos, block);
                }
            });
        }
    }

    // 位置ViewHolder
    class LocationViewHolder extends RecyclerView.ViewHolder {
        ImageView ivImage;
        TextView tvLocation;
        TextView tvLocationDetail;
        ImageView ivDelete;

        LocationViewHolder(View itemView) {
            super(itemView);
            ivImage = itemView.findViewById(R.id.ivImage);
            tvLocation = itemView.findViewById(R.id.tvLocation);
            tvLocationDetail = itemView.findViewById(R.id.tvLocationDetail);
            ivDelete = itemView.findViewById(R.id.ivDelete);

            ivDelete.setOnClickListener(v -> {
                int pos = getAdapterPosition();
                if (deleteListener != null && pos != RecyclerView.NO_POSITION
                        && pos >= 0 && pos < blockList.size()) {
                    deleteListener.onDelete(pos);
                }
            });
        }

        void bind(NoteBlock block) {
            tvLocation.setText(block.locationName);
            tvLocationDetail.setText(block.locationAddress);
            itemView.setOnClickListener(v -> {
                int pos = getAdapterPosition();
                if (clickListener != null && pos != RecyclerView.NO_POSITION
                        && pos >= 0 && pos < blockList.size()) {
                    clickListener.onBlockClick(pos, block);
                }
            });
        }
    }
}
