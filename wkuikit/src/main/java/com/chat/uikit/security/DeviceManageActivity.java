package com.chat.uikit.security;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKDeviceUtils;
import com.chat.base.utils.WKDialogUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityDeviceManageBinding;
import com.chat.uikit.databinding.ItemDeviceListBinding;

import java.util.ArrayList;
import java.util.List;

/**
 * 2024-08-31
 * 设备管理页面
 */
public class DeviceManageActivity extends WKBaseActivity<ActivityDeviceManageBinding> {

    private DeviceAdapter adapter;
    private final List<DeviceInfo> deviceList = new ArrayList<>();

    @Override
    protected ActivityDeviceManageBinding getViewBinding() {
        return ActivityDeviceManageBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(android.widget.TextView titleTv) {
        titleTv.setText(R.string.device_management);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        wkVBinding.deviceRv.setLayoutManager(new LinearLayoutManager(this));
        adapter = new DeviceAdapter(this, deviceList);
        wkVBinding.deviceRv.setAdapter(adapter);

        // 添加模拟数据
        loadDeviceList();
    }

    @Override
    protected void initListener() {
        adapter.setOnItemLongClickListener(position -> {
            DeviceInfo device = deviceList.get(position);
            if (!device.isCurrent) {
                WKDialogUtils.getInstance().showDialog(this, "下线设备",
                        "确定要下线该设备吗？", true, "", "确定", 0, 0, index -> {
                            if (index == 1) {
                                deviceList.remove(position);
                                adapter.notifyItemRemoved(position);
                            }
                        });
            }
        });
    }

    private void loadDeviceList() {
        deviceList.clear();

        // 当前设备
        DeviceInfo currentDevice = new DeviceInfo();
        currentDevice.deviceName = WKDeviceUtils.getInstance().getDeviceName();
        currentDevice.deviceInfo = "当前设备 · Android " + android.os.Build.VERSION.RELEASE;
        currentDevice.isOnline = true;
        currentDevice.isCurrent = true;
        deviceList.add(currentDevice);

        // 其他设备（模拟数据）
        DeviceInfo device2 = new DeviceInfo();
        device2.deviceName = "iPhone 15 Pro";
        device2.deviceInfo = "最后登录: 2024-08-30 18:30";
        device2.isOnline = false;
        device2.isCurrent = false;
        deviceList.add(device2);

        DeviceInfo device3 = new DeviceInfo();
        device3.deviceName = "Windows PC";
        device3.deviceInfo = "最后登录: 2024-08-28 09:15";
        device3.isOnline = false;
        device3.isCurrent = false;
        deviceList.add(device3);

        DeviceInfo device4 = new DeviceInfo();
        device4.deviceName = "iPad Pro";
        device4.deviceInfo = "最后登录: 2024-08-25 14:20";
        device4.isOnline = false;
        device4.isCurrent = false;
        deviceList.add(device4);

        adapter.notifyDataSetChanged();
    }

    static class DeviceInfo {
        String deviceName;
        String deviceInfo;
        boolean isOnline;
        boolean isCurrent;
    }

    static class DeviceAdapter extends RecyclerView.Adapter<DeviceAdapter.DeviceViewHolder> {

        private final Context context;
        private final List<DeviceInfo> list;
        private OnItemLongClickListener longClickListener;

        interface OnItemLongClickListener {
            void onItemLongClick(int position);
        }

        void setOnItemLongClickListener(OnItemLongClickListener listener) {
            this.longClickListener = listener;
        }

        DeviceAdapter(Context context, List<DeviceInfo> list) {
            this.context = context;
            this.list = list;
        }

        @NonNull
        @Override
        public DeviceViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            ItemDeviceListBinding binding = ItemDeviceListBinding.inflate(
                    LayoutInflater.from(context), parent, false);
            return new DeviceViewHolder(binding);
        }

        @Override
        public void onBindViewHolder(@NonNull DeviceViewHolder holder, int position) {
            DeviceInfo device = list.get(position);
            holder.binding.deviceNameTv.setText(device.deviceName);
            holder.binding.deviceInfoTv.setText(device.deviceInfo);

            if (device.isOnline) {
                holder.binding.deviceStatusTv.setText("在线");
                holder.binding.deviceStatusTv.setBackgroundResource(R.drawable.shape_green_bg);
                holder.binding.deviceStatusTv.setTextColor(context.getResources().getColor(R.color.white));
            } else {
                holder.binding.deviceStatusTv.setText("离线");
                holder.binding.deviceStatusTv.setBackgroundResource(R.drawable.shape_gray_bg);
                holder.binding.deviceStatusTv.setTextColor(context.getResources().getColor(R.color.color999));
            }

            holder.itemView.setOnLongClickListener(v -> {
                if (longClickListener != null) {
                    longClickListener.onItemLongClick(position);
                }
                return true;
            });
        }

        @Override
        public int getItemCount() {
            return list.size();
        }

        static class DeviceViewHolder extends RecyclerView.ViewHolder {
            ItemDeviceListBinding binding;

            DeviceViewHolder(ItemDeviceListBinding binding) {
                super(binding.getRoot());
                this.binding = binding;
            }
        }
    }
}
