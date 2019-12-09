typedef struct astNode_impl
{
	char *str;
        char op;
        int nodeIdx;
        char *id;
        struct astNode_impl* left;
        struct astNode_impl* right;
} astNode;
