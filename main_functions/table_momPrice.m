function [tbl_momPrice] = table_momPrice(momPrice)
nMoments = size(momPrice,2);

switch nMoments
    case 1
        tbl_momPrice = table(momPrice(:,1), 'VariableNames', {'momPrice1'});
    case 2
        tbl_momPrice = table(momPrice(:,1), momPrice(:,2),'VariableNames', {'momPrice1', 'momPrice2'} );
    case 3
        tbl_momPrice = table(momPrice(:,1), momPrice(:,2), momPrice(:,3), ...
            'VariableNames', {'momPrice1', 'momPrice2', 'momPrice3'});
    case 4
        tbl_momPrice = table(momPrice(:,1), momPrice(:,2), momPrice(:,3), momPrice(:,4), ...
            'VariableNames', {'momPrice1', 'momPrice2', 'momPrice3', 'momPrice4'});
end
