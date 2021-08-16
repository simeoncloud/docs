@{
    ExcludeRules = @(
        'PSAvoidUsingCmdletAliases'
        'PSAvoidUsingWriteHost'
        'PSAvoidUsingInvokeExpression'
        'PSAvoidUsingUsernameAndPasswordParams'
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSUseShouldProcessForStateChangingFunctions'
        'PSAvoidUsingPlainTextForPassword'
    )
}
