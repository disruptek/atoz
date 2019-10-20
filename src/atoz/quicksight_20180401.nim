
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon QuickSight
## version: 2018-04-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon QuickSight API Reference</fullname> <p>Amazon QuickSight is a fully managed, serverless, cloud business intelligence service that makes it easy to extend data and insights to every user in your organization. This API interface reference contains documentation for a programming interface that you can use to manage Amazon QuickSight. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/quicksight/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "quicksight.ap-northeast-1.amazonaws.com", "ap-southeast-1": "quicksight.ap-southeast-1.amazonaws.com",
                           "us-west-2": "quicksight.us-west-2.amazonaws.com",
                           "eu-west-2": "quicksight.eu-west-2.amazonaws.com", "ap-northeast-3": "quicksight.ap-northeast-3.amazonaws.com", "eu-central-1": "quicksight.eu-central-1.amazonaws.com",
                           "us-east-2": "quicksight.us-east-2.amazonaws.com",
                           "us-east-1": "quicksight.us-east-1.amazonaws.com", "cn-northwest-1": "quicksight.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "quicksight.ap-south-1.amazonaws.com",
                           "eu-north-1": "quicksight.eu-north-1.amazonaws.com", "ap-northeast-2": "quicksight.ap-northeast-2.amazonaws.com",
                           "us-west-1": "quicksight.us-west-1.amazonaws.com", "us-gov-east-1": "quicksight.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "quicksight.eu-west-3.amazonaws.com", "cn-north-1": "quicksight.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "quicksight.sa-east-1.amazonaws.com",
                           "eu-west-1": "quicksight.eu-west-1.amazonaws.com", "us-gov-west-1": "quicksight.us-gov-west-1.amazonaws.com", "ap-southeast-2": "quicksight.ap-southeast-2.amazonaws.com", "ca-central-1": "quicksight.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "quicksight.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "quicksight.ap-southeast-1.amazonaws.com",
      "us-west-2": "quicksight.us-west-2.amazonaws.com",
      "eu-west-2": "quicksight.eu-west-2.amazonaws.com",
      "ap-northeast-3": "quicksight.ap-northeast-3.amazonaws.com",
      "eu-central-1": "quicksight.eu-central-1.amazonaws.com",
      "us-east-2": "quicksight.us-east-2.amazonaws.com",
      "us-east-1": "quicksight.us-east-1.amazonaws.com",
      "cn-northwest-1": "quicksight.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "quicksight.ap-south-1.amazonaws.com",
      "eu-north-1": "quicksight.eu-north-1.amazonaws.com",
      "ap-northeast-2": "quicksight.ap-northeast-2.amazonaws.com",
      "us-west-1": "quicksight.us-west-1.amazonaws.com",
      "us-gov-east-1": "quicksight.us-gov-east-1.amazonaws.com",
      "eu-west-3": "quicksight.eu-west-3.amazonaws.com",
      "cn-north-1": "quicksight.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "quicksight.sa-east-1.amazonaws.com",
      "eu-west-1": "quicksight.eu-west-1.amazonaws.com",
      "us-gov-west-1": "quicksight.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "quicksight.ap-southeast-2.amazonaws.com",
      "ca-central-1": "quicksight.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "quicksight"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateGroup_592977 = ref object of OpenApiRestCall_592364
proc url_CreateGroup_592979(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateGroup_592978(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group --aws-account-id=111122223333 --namespace=default --group-name="Sales-Management" --description="Sales Management - Forecasting" </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_592980 = path.getOrDefault("AwsAccountId")
  valid_592980 = validateParameter(valid_592980, JString, required = true,
                                 default = nil)
  if valid_592980 != nil:
    section.add "AwsAccountId", valid_592980
  var valid_592981 = path.getOrDefault("Namespace")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "Namespace", valid_592981
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592982 = header.getOrDefault("X-Amz-Signature")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Signature", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Content-Sha256", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Date")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Date", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Credential")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Credential", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Security-Token")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Security-Token", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Algorithm")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Algorithm", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-SignedHeaders", valid_592988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592990: Call_CreateGroup_592977; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group --aws-account-id=111122223333 --namespace=default --group-name="Sales-Management" --description="Sales Management - Forecasting" </code> </p>
  ## 
  let valid = call_592990.validator(path, query, header, formData, body)
  let scheme = call_592990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592990.url(scheme.get, call_592990.host, call_592990.base,
                         call_592990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592990, url, valid)

proc call*(call_592991: Call_CreateGroup_592977; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group --aws-account-id=111122223333 --namespace=default --group-name="Sales-Management" --description="Sales Management - Forecasting" </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_592992 = newJObject()
  var body_592993 = newJObject()
  add(path_592992, "AwsAccountId", newJString(AwsAccountId))
  add(path_592992, "Namespace", newJString(Namespace))
  if body != nil:
    body_592993 = body
  result = call_592991.call(path_592992, nil, nil, nil, body_592993)

var createGroup* = Call_CreateGroup_592977(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                        validator: validate_CreateGroup_592978,
                                        base: "/", url: url_CreateGroup_592979,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_592703 = ref object of OpenApiRestCall_592364
proc url_ListGroups_592705(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListGroups_592704(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all user groups in Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/*</code>.</p> <p>The response is a list of group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-groups -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_592831 = path.getOrDefault("AwsAccountId")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = nil)
  if valid_592831 != nil:
    section.add "AwsAccountId", valid_592831
  var valid_592832 = path.getOrDefault("Namespace")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = nil)
  if valid_592832 != nil:
    section.add "Namespace", valid_592832
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_592833 = query.getOrDefault("max-results")
  valid_592833 = validateParameter(valid_592833, JInt, required = false, default = nil)
  if valid_592833 != nil:
    section.add "max-results", valid_592833
  var valid_592834 = query.getOrDefault("next-token")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "next-token", valid_592834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592835 = header.getOrDefault("X-Amz-Signature")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Signature", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Content-Sha256", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Date")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Date", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Credential")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Credential", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Security-Token")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Security-Token", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-Algorithm")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-Algorithm", valid_592840
  var valid_592841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592841 = validateParameter(valid_592841, JString, required = false,
                                 default = nil)
  if valid_592841 != nil:
    section.add "X-Amz-SignedHeaders", valid_592841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592864: Call_ListGroups_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all user groups in Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/*</code>.</p> <p>The response is a list of group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-groups -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ## 
  let valid = call_592864.validator(path, query, header, formData, body)
  let scheme = call_592864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592864.url(scheme.get, call_592864.host, call_592864.base,
                         call_592864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592864, url, valid)

proc call*(call_592935: Call_ListGroups_592703; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listGroups
  ## <p>Lists all user groups in Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/*</code>.</p> <p>The response is a list of group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-groups -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_592936 = newJObject()
  var query_592938 = newJObject()
  add(path_592936, "AwsAccountId", newJString(AwsAccountId))
  add(path_592936, "Namespace", newJString(Namespace))
  add(query_592938, "max-results", newJInt(maxResults))
  add(query_592938, "next-token", newJString(nextToken))
  result = call_592935.call(path_592936, query_592938, nil, nil, nil)

var listGroups* = Call_ListGroups_592703(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                      validator: validate_ListGroups_592704,
                                      base: "/", url: url_ListGroups_592705,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupMembership_592994 = ref object of OpenApiRestCall_592364
proc url_CreateGroupMembership_592996(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  assert "MemberName" in path, "`MemberName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "MemberName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateGroupMembership_592995(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an Amazon QuickSight user to an Amazon QuickSight group. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p>The response is the group member object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales --member-name=Pat </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to add to the group membership.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_592997 = path.getOrDefault("GroupName")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "GroupName", valid_592997
  var valid_592998 = path.getOrDefault("AwsAccountId")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = nil)
  if valid_592998 != nil:
    section.add "AwsAccountId", valid_592998
  var valid_592999 = path.getOrDefault("Namespace")
  valid_592999 = validateParameter(valid_592999, JString, required = true,
                                 default = nil)
  if valid_592999 != nil:
    section.add "Namespace", valid_592999
  var valid_593000 = path.getOrDefault("MemberName")
  valid_593000 = validateParameter(valid_593000, JString, required = true,
                                 default = nil)
  if valid_593000 != nil:
    section.add "MemberName", valid_593000
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593001 = header.getOrDefault("X-Amz-Signature")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Signature", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Content-Sha256", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Date")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Date", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Credential")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Credential", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Security-Token")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Security-Token", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Algorithm")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Algorithm", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-SignedHeaders", valid_593007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593008: Call_CreateGroupMembership_592994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds an Amazon QuickSight user to an Amazon QuickSight group. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p>The response is the group member object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales --member-name=Pat </code> </p>
  ## 
  let valid = call_593008.validator(path, query, header, formData, body)
  let scheme = call_593008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593008.url(scheme.get, call_593008.host, call_593008.base,
                         call_593008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593008, url, valid)

proc call*(call_593009: Call_CreateGroupMembership_592994; GroupName: string;
          AwsAccountId: string; Namespace: string; MemberName: string): Recallable =
  ## createGroupMembership
  ## <p>Adds an Amazon QuickSight user to an Amazon QuickSight group. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p>The response is the group member object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales --member-name=Pat </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to add to the group membership.
  var path_593010 = newJObject()
  add(path_593010, "GroupName", newJString(GroupName))
  add(path_593010, "AwsAccountId", newJString(AwsAccountId))
  add(path_593010, "Namespace", newJString(Namespace))
  add(path_593010, "MemberName", newJString(MemberName))
  result = call_593009.call(path_593010, nil, nil, nil, nil)

var createGroupMembership* = Call_CreateGroupMembership_592994(
    name: "createGroupMembership", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_CreateGroupMembership_592995, base: "/",
    url: url_CreateGroupMembership_592996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroupMembership_593011 = ref object of OpenApiRestCall_592364
proc url_DeleteGroupMembership_593013(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  assert "MemberName" in path, "`MemberName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "MemberName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteGroupMembership_593012(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a user from a group so that the user is no longer a member of the group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales-Management --member-name=Charlie </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to delete from the group membership.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_593014 = path.getOrDefault("GroupName")
  valid_593014 = validateParameter(valid_593014, JString, required = true,
                                 default = nil)
  if valid_593014 != nil:
    section.add "GroupName", valid_593014
  var valid_593015 = path.getOrDefault("AwsAccountId")
  valid_593015 = validateParameter(valid_593015, JString, required = true,
                                 default = nil)
  if valid_593015 != nil:
    section.add "AwsAccountId", valid_593015
  var valid_593016 = path.getOrDefault("Namespace")
  valid_593016 = validateParameter(valid_593016, JString, required = true,
                                 default = nil)
  if valid_593016 != nil:
    section.add "Namespace", valid_593016
  var valid_593017 = path.getOrDefault("MemberName")
  valid_593017 = validateParameter(valid_593017, JString, required = true,
                                 default = nil)
  if valid_593017 != nil:
    section.add "MemberName", valid_593017
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593018 = header.getOrDefault("X-Amz-Signature")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Signature", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Content-Sha256", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Date")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Date", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Credential")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Credential", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Security-Token")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Security-Token", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-Algorithm")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-Algorithm", valid_593023
  var valid_593024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "X-Amz-SignedHeaders", valid_593024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593025: Call_DeleteGroupMembership_593011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a user from a group so that the user is no longer a member of the group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales-Management --member-name=Charlie </code> </p>
  ## 
  let valid = call_593025.validator(path, query, header, formData, body)
  let scheme = call_593025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593025.url(scheme.get, call_593025.host, call_593025.base,
                         call_593025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593025, url, valid)

proc call*(call_593026: Call_DeleteGroupMembership_593011; GroupName: string;
          AwsAccountId: string; Namespace: string; MemberName: string): Recallable =
  ## deleteGroupMembership
  ## <p>Removes a user from a group so that the user is no longer a member of the group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales-Management --member-name=Charlie </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to delete from the group membership.
  var path_593027 = newJObject()
  add(path_593027, "GroupName", newJString(GroupName))
  add(path_593027, "AwsAccountId", newJString(AwsAccountId))
  add(path_593027, "Namespace", newJString(Namespace))
  add(path_593027, "MemberName", newJString(MemberName))
  result = call_593026.call(path_593027, nil, nil, nil, nil)

var deleteGroupMembership* = Call_DeleteGroupMembership_593011(
    name: "deleteGroupMembership", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_DeleteGroupMembership_593012, base: "/",
    url: url_DeleteGroupMembership_593013, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_593044 = ref object of OpenApiRestCall_592364
proc url_UpdateGroup_593046(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateGroup_593045(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes a group description. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-group --aws-account-id=111122223333 --namespace=default --group-name=Sales --description="Sales BI Dashboards" </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to update.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_593047 = path.getOrDefault("GroupName")
  valid_593047 = validateParameter(valid_593047, JString, required = true,
                                 default = nil)
  if valid_593047 != nil:
    section.add "GroupName", valid_593047
  var valid_593048 = path.getOrDefault("AwsAccountId")
  valid_593048 = validateParameter(valid_593048, JString, required = true,
                                 default = nil)
  if valid_593048 != nil:
    section.add "AwsAccountId", valid_593048
  var valid_593049 = path.getOrDefault("Namespace")
  valid_593049 = validateParameter(valid_593049, JString, required = true,
                                 default = nil)
  if valid_593049 != nil:
    section.add "Namespace", valid_593049
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593050 = header.getOrDefault("X-Amz-Signature")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Signature", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-Content-Sha256", valid_593051
  var valid_593052 = header.getOrDefault("X-Amz-Date")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Date", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Credential")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Credential", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Security-Token")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Security-Token", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Algorithm")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Algorithm", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-SignedHeaders", valid_593056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593058: Call_UpdateGroup_593044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes a group description. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-group --aws-account-id=111122223333 --namespace=default --group-name=Sales --description="Sales BI Dashboards" </code> </p>
  ## 
  let valid = call_593058.validator(path, query, header, formData, body)
  let scheme = call_593058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593058.url(scheme.get, call_593058.host, call_593058.base,
                         call_593058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593058, url, valid)

proc call*(call_593059: Call_UpdateGroup_593044; GroupName: string;
          AwsAccountId: string; Namespace: string; body: JsonNode): Recallable =
  ## updateGroup
  ## <p>Changes a group description. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-group --aws-account-id=111122223333 --namespace=default --group-name=Sales --description="Sales BI Dashboards" </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to update.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_593060 = newJObject()
  var body_593061 = newJObject()
  add(path_593060, "GroupName", newJString(GroupName))
  add(path_593060, "AwsAccountId", newJString(AwsAccountId))
  add(path_593060, "Namespace", newJString(Namespace))
  if body != nil:
    body_593061 = body
  result = call_593059.call(path_593060, nil, nil, nil, body_593061)

var updateGroup* = Call_UpdateGroup_593044(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_UpdateGroup_593045,
                                        base: "/", url: url_UpdateGroup_593046,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_593028 = ref object of OpenApiRestCall_592364
proc url_DescribeGroup_593030(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeGroup_593029(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is the group object. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-group -\-aws-account-id=11112222333 -\-namespace=default -\-group-name=Sales </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_593031 = path.getOrDefault("GroupName")
  valid_593031 = validateParameter(valid_593031, JString, required = true,
                                 default = nil)
  if valid_593031 != nil:
    section.add "GroupName", valid_593031
  var valid_593032 = path.getOrDefault("AwsAccountId")
  valid_593032 = validateParameter(valid_593032, JString, required = true,
                                 default = nil)
  if valid_593032 != nil:
    section.add "AwsAccountId", valid_593032
  var valid_593033 = path.getOrDefault("Namespace")
  valid_593033 = validateParameter(valid_593033, JString, required = true,
                                 default = nil)
  if valid_593033 != nil:
    section.add "Namespace", valid_593033
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593034 = header.getOrDefault("X-Amz-Signature")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Signature", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Content-Sha256", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Date")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Date", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-Credential")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Credential", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Security-Token")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Security-Token", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Algorithm")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Algorithm", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-SignedHeaders", valid_593040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593041: Call_DescribeGroup_593028; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is the group object. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-group -\-aws-account-id=11112222333 -\-namespace=default -\-group-name=Sales </code> </p>
  ## 
  let valid = call_593041.validator(path, query, header, formData, body)
  let scheme = call_593041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593041.url(scheme.get, call_593041.host, call_593041.base,
                         call_593041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593041, url, valid)

proc call*(call_593042: Call_DescribeGroup_593028; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## describeGroup
  ## <p>Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is the group object. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-group -\-aws-account-id=11112222333 -\-namespace=default -\-group-name=Sales </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_593043 = newJObject()
  add(path_593043, "GroupName", newJString(GroupName))
  add(path_593043, "AwsAccountId", newJString(AwsAccountId))
  add(path_593043, "Namespace", newJString(Namespace))
  result = call_593042.call(path_593043, nil, nil, nil, nil)

var describeGroup* = Call_DescribeGroup_593028(name: "describeGroup",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DescribeGroup_593029, base: "/", url: url_DescribeGroup_593030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_593062 = ref object of OpenApiRestCall_592364
proc url_DeleteGroup_593064(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteGroup_593063(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a user group from Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group -\-aws-account-id=111122223333 -\-namespace=default -\-group-name=Sales-Management </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_593065 = path.getOrDefault("GroupName")
  valid_593065 = validateParameter(valid_593065, JString, required = true,
                                 default = nil)
  if valid_593065 != nil:
    section.add "GroupName", valid_593065
  var valid_593066 = path.getOrDefault("AwsAccountId")
  valid_593066 = validateParameter(valid_593066, JString, required = true,
                                 default = nil)
  if valid_593066 != nil:
    section.add "AwsAccountId", valid_593066
  var valid_593067 = path.getOrDefault("Namespace")
  valid_593067 = validateParameter(valid_593067, JString, required = true,
                                 default = nil)
  if valid_593067 != nil:
    section.add "Namespace", valid_593067
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593068 = header.getOrDefault("X-Amz-Signature")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "X-Amz-Signature", valid_593068
  var valid_593069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593069 = validateParameter(valid_593069, JString, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "X-Amz-Content-Sha256", valid_593069
  var valid_593070 = header.getOrDefault("X-Amz-Date")
  valid_593070 = validateParameter(valid_593070, JString, required = false,
                                 default = nil)
  if valid_593070 != nil:
    section.add "X-Amz-Date", valid_593070
  var valid_593071 = header.getOrDefault("X-Amz-Credential")
  valid_593071 = validateParameter(valid_593071, JString, required = false,
                                 default = nil)
  if valid_593071 != nil:
    section.add "X-Amz-Credential", valid_593071
  var valid_593072 = header.getOrDefault("X-Amz-Security-Token")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Security-Token", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Algorithm")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Algorithm", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-SignedHeaders", valid_593074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593075: Call_DeleteGroup_593062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a user group from Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group -\-aws-account-id=111122223333 -\-namespace=default -\-group-name=Sales-Management </code> </p>
  ## 
  let valid = call_593075.validator(path, query, header, formData, body)
  let scheme = call_593075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593075.url(scheme.get, call_593075.host, call_593075.base,
                         call_593075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593075, url, valid)

proc call*(call_593076: Call_DeleteGroup_593062; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## deleteGroup
  ## <p>Removes a user group from Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group -\-aws-account-id=111122223333 -\-namespace=default -\-group-name=Sales-Management </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_593077 = newJObject()
  add(path_593077, "GroupName", newJString(GroupName))
  add(path_593077, "AwsAccountId", newJString(AwsAccountId))
  add(path_593077, "Namespace", newJString(Namespace))
  result = call_593076.call(path_593077, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_593062(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_DeleteGroup_593063,
                                        base: "/", url: url_DeleteGroup_593064,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_593094 = ref object of OpenApiRestCall_592364
proc url_UpdateUser_593096(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateUser_593095(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an Amazon QuickSight user.</p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a user object that contains the user's Amazon QuickSight user name, email address, active or inactive status in Amazon QuickSight, Amazon QuickSight role, and Amazon Resource Name (ARN). </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-user --user-name=Pat --role=ADMIN --email=new_address@amazon.com --aws-account-id=111122223333 --namespace=default --region=us-east-1 </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_593097 = path.getOrDefault("AwsAccountId")
  valid_593097 = validateParameter(valid_593097, JString, required = true,
                                 default = nil)
  if valid_593097 != nil:
    section.add "AwsAccountId", valid_593097
  var valid_593098 = path.getOrDefault("Namespace")
  valid_593098 = validateParameter(valid_593098, JString, required = true,
                                 default = nil)
  if valid_593098 != nil:
    section.add "Namespace", valid_593098
  var valid_593099 = path.getOrDefault("UserName")
  valid_593099 = validateParameter(valid_593099, JString, required = true,
                                 default = nil)
  if valid_593099 != nil:
    section.add "UserName", valid_593099
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593100 = header.getOrDefault("X-Amz-Signature")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-Signature", valid_593100
  var valid_593101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Content-Sha256", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Date")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Date", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Credential")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Credential", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Security-Token")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Security-Token", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Algorithm")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Algorithm", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-SignedHeaders", valid_593106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593108: Call_UpdateUser_593094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon QuickSight user.</p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a user object that contains the user's Amazon QuickSight user name, email address, active or inactive status in Amazon QuickSight, Amazon QuickSight role, and Amazon Resource Name (ARN). </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-user --user-name=Pat --role=ADMIN --email=new_address@amazon.com --aws-account-id=111122223333 --namespace=default --region=us-east-1 </code> </p>
  ## 
  let valid = call_593108.validator(path, query, header, formData, body)
  let scheme = call_593108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593108.url(scheme.get, call_593108.host, call_593108.base,
                         call_593108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593108, url, valid)

proc call*(call_593109: Call_UpdateUser_593094; AwsAccountId: string;
          Namespace: string; UserName: string; body: JsonNode): Recallable =
  ## updateUser
  ## <p>Updates an Amazon QuickSight user.</p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a user object that contains the user's Amazon QuickSight user name, email address, active or inactive status in Amazon QuickSight, Amazon QuickSight role, and Amazon Resource Name (ARN). </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-user --user-name=Pat --role=ADMIN --email=new_address@amazon.com --aws-account-id=111122223333 --namespace=default --region=us-east-1 </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to update.
  ##   body: JObject (required)
  var path_593110 = newJObject()
  var body_593111 = newJObject()
  add(path_593110, "AwsAccountId", newJString(AwsAccountId))
  add(path_593110, "Namespace", newJString(Namespace))
  add(path_593110, "UserName", newJString(UserName))
  if body != nil:
    body_593111 = body
  result = call_593109.call(path_593110, nil, nil, nil, body_593111)

var updateUser* = Call_UpdateUser_593094(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_UpdateUser_593095,
                                      base: "/", url: url_UpdateUser_593096,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_593078 = ref object of OpenApiRestCall_592364
proc url_DescribeUser_593080(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DescribeUser_593079(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a user, given the user name. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a user object that contains the user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to describe.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_593081 = path.getOrDefault("AwsAccountId")
  valid_593081 = validateParameter(valid_593081, JString, required = true,
                                 default = nil)
  if valid_593081 != nil:
    section.add "AwsAccountId", valid_593081
  var valid_593082 = path.getOrDefault("Namespace")
  valid_593082 = validateParameter(valid_593082, JString, required = true,
                                 default = nil)
  if valid_593082 != nil:
    section.add "Namespace", valid_593082
  var valid_593083 = path.getOrDefault("UserName")
  valid_593083 = validateParameter(valid_593083, JString, required = true,
                                 default = nil)
  if valid_593083 != nil:
    section.add "UserName", valid_593083
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593084 = header.getOrDefault("X-Amz-Signature")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Signature", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-Content-Sha256", valid_593085
  var valid_593086 = header.getOrDefault("X-Amz-Date")
  valid_593086 = validateParameter(valid_593086, JString, required = false,
                                 default = nil)
  if valid_593086 != nil:
    section.add "X-Amz-Date", valid_593086
  var valid_593087 = header.getOrDefault("X-Amz-Credential")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Credential", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Security-Token")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Security-Token", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Algorithm")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Algorithm", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-SignedHeaders", valid_593090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593091: Call_DescribeUser_593078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a user, given the user name. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a user object that contains the user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ## 
  let valid = call_593091.validator(path, query, header, formData, body)
  let scheme = call_593091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593091.url(scheme.get, call_593091.host, call_593091.base,
                         call_593091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593091, url, valid)

proc call*(call_593092: Call_DescribeUser_593078; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## describeUser
  ## <p>Returns information about a user, given the user name. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a user object that contains the user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to describe.
  var path_593093 = newJObject()
  add(path_593093, "AwsAccountId", newJString(AwsAccountId))
  add(path_593093, "Namespace", newJString(Namespace))
  add(path_593093, "UserName", newJString(UserName))
  result = call_593092.call(path_593093, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_593078(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
    validator: validate_DescribeUser_593079, base: "/", url: url_DescribeUser_593080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_593112 = ref object of OpenApiRestCall_592364
proc url_DeleteUser_593114(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteUser_593113(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt; </i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_593115 = path.getOrDefault("AwsAccountId")
  valid_593115 = validateParameter(valid_593115, JString, required = true,
                                 default = nil)
  if valid_593115 != nil:
    section.add "AwsAccountId", valid_593115
  var valid_593116 = path.getOrDefault("Namespace")
  valid_593116 = validateParameter(valid_593116, JString, required = true,
                                 default = nil)
  if valid_593116 != nil:
    section.add "Namespace", valid_593116
  var valid_593117 = path.getOrDefault("UserName")
  valid_593117 = validateParameter(valid_593117, JString, required = true,
                                 default = nil)
  if valid_593117 != nil:
    section.add "UserName", valid_593117
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593118 = header.getOrDefault("X-Amz-Signature")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Signature", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Content-Sha256", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Date")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Date", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Credential")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Credential", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Security-Token")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Security-Token", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-Algorithm")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-Algorithm", valid_593123
  var valid_593124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593124 = validateParameter(valid_593124, JString, required = false,
                                 default = nil)
  if valid_593124 != nil:
    section.add "X-Amz-SignedHeaders", valid_593124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593125: Call_DeleteUser_593112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt; </i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ## 
  let valid = call_593125.validator(path, query, header, formData, body)
  let scheme = call_593125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593125.url(scheme.get, call_593125.host, call_593125.base,
                         call_593125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593125, url, valid)

proc call*(call_593126: Call_DeleteUser_593112; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## deleteUser
  ## <p>Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt; </i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to delete.
  var path_593127 = newJObject()
  add(path_593127, "AwsAccountId", newJString(AwsAccountId))
  add(path_593127, "Namespace", newJString(Namespace))
  add(path_593127, "UserName", newJString(UserName))
  result = call_593126.call(path_593127, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_593112(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_DeleteUser_593113,
                                      base: "/", url: url_DeleteUser_593114,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserByPrincipalId_593128 = ref object of OpenApiRestCall_592364
proc url_DeleteUserByPrincipalId_593130(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "PrincipalId" in path, "`PrincipalId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/user-principals/"),
               (kind: VariableSegment, value: "PrincipalId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteUserByPrincipalId_593129(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a user identified by its principal ID. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt; </i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user-by-principal-id --aws-account-id=111122223333 --namespace=default --principal-id=ABCDEFJA26JLI7EUUOEHS </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: JString (required)
  ##              : The principal ID of the user.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_593131 = path.getOrDefault("AwsAccountId")
  valid_593131 = validateParameter(valid_593131, JString, required = true,
                                 default = nil)
  if valid_593131 != nil:
    section.add "AwsAccountId", valid_593131
  var valid_593132 = path.getOrDefault("Namespace")
  valid_593132 = validateParameter(valid_593132, JString, required = true,
                                 default = nil)
  if valid_593132 != nil:
    section.add "Namespace", valid_593132
  var valid_593133 = path.getOrDefault("PrincipalId")
  valid_593133 = validateParameter(valid_593133, JString, required = true,
                                 default = nil)
  if valid_593133 != nil:
    section.add "PrincipalId", valid_593133
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593134 = header.getOrDefault("X-Amz-Signature")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Signature", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Content-Sha256", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Date")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Date", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Credential")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Credential", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Security-Token")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Security-Token", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-Algorithm")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-Algorithm", valid_593139
  var valid_593140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593140 = validateParameter(valid_593140, JString, required = false,
                                 default = nil)
  if valid_593140 != nil:
    section.add "X-Amz-SignedHeaders", valid_593140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593141: Call_DeleteUserByPrincipalId_593128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user identified by its principal ID. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt; </i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user-by-principal-id --aws-account-id=111122223333 --namespace=default --principal-id=ABCDEFJA26JLI7EUUOEHS </code> </p>
  ## 
  let valid = call_593141.validator(path, query, header, formData, body)
  let scheme = call_593141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593141.url(scheme.get, call_593141.host, call_593141.base,
                         call_593141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593141, url, valid)

proc call*(call_593142: Call_DeleteUserByPrincipalId_593128; AwsAccountId: string;
          Namespace: string; PrincipalId: string): Recallable =
  ## deleteUserByPrincipalId
  ## <p>Deletes a user identified by its principal ID. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt; </i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user-by-principal-id --aws-account-id=111122223333 --namespace=default --principal-id=ABCDEFJA26JLI7EUUOEHS </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the user.
  var path_593143 = newJObject()
  add(path_593143, "AwsAccountId", newJString(AwsAccountId))
  add(path_593143, "Namespace", newJString(Namespace))
  add(path_593143, "PrincipalId", newJString(PrincipalId))
  result = call_593142.call(path_593143, nil, nil, nil, nil)

var deleteUserByPrincipalId* = Call_DeleteUserByPrincipalId_593128(
    name: "deleteUserByPrincipalId", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}",
    validator: validate_DeleteUserByPrincipalId_593129, base: "/",
    url: url_DeleteUserByPrincipalId_593130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDashboardEmbedUrl_593144 = ref object of OpenApiRestCall_592364
proc url_GetDashboardEmbedUrl_593146(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/embed-url#creds-type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDashboardEmbedUrl_593145(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a server-side embeddable URL and authorization code. Before this can work properly, first you need to configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/en_us/quicksight/latest/user/embedding.html"> Embedding Amazon QuickSight Dashboards</a>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p> <p> <b>CLI Sample:</b> </p> <p>Assume the role with permissions enabled for actions: <code>quickSight:RegisterUser</code> and <code>quicksight:GetDashboardEmbedURL</code>. You can use assume-role, assume-role-with-web-identity, or assume-role-with-saml. </p> <p> <code>aws sts assume-role --role-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --role-session-name embeddingsession</code> </p> <p>If the user does not exist in QuickSight, register the user:</p> <p> <code>aws quicksight register-user --aws-account-id 111122223333 --namespace default --identity-type IAM --iam-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --user-role READER --session-name "embeddingsession" --email user123@example.com --region us-east-1</code> </p> <p>Get the URL for the embedded dashboard</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type IAM</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are embedding.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to IAM policy
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_593147 = path.getOrDefault("AwsAccountId")
  valid_593147 = validateParameter(valid_593147, JString, required = true,
                                 default = nil)
  if valid_593147 != nil:
    section.add "AwsAccountId", valid_593147
  var valid_593148 = path.getOrDefault("DashboardId")
  valid_593148 = validateParameter(valid_593148, JString, required = true,
                                 default = nil)
  if valid_593148 != nil:
    section.add "DashboardId", valid_593148
  result.add "path", section
  ## parameters in `query` object:
  ##   reset-disabled: JBool
  ##                 : Remove the reset button on embedded dashboard. The default is FALSE, which allows the reset button.
  ##   creds-type: JString (required)
  ##             : The authentication method the user uses to sign in (IAM only).
  ##   user-arn: JString
  ##           : <p>The Amazon QuickSight user's ARN, for use with <code>QUICKSIGHT</code> identity type. You can use this for any of the following:</p> <ul> <li> <p>Amazon QuickSight users in your account (readers, authors, or admins)</p> </li> <li> <p>AD users</p> </li> <li> <p>Invited non-federated users</p> </li> <li> <p>Federated IAM users</p> </li> <li> <p>Federated IAM role-based sessions</p> </li> </ul>
  ##   session-lifetime: JInt
  ##                   : How many minutes the session is valid. The session lifetime must be between 15 and 600 minutes.
  ##   undo-redo-disabled: JBool
  ##                     : Remove the undo/redo button on embedded dashboard. The default is FALSE, which enables the undo/redo button.
  section = newJObject()
  var valid_593149 = query.getOrDefault("reset-disabled")
  valid_593149 = validateParameter(valid_593149, JBool, required = false, default = nil)
  if valid_593149 != nil:
    section.add "reset-disabled", valid_593149
  assert query != nil,
        "query argument is necessary due to required `creds-type` field"
  var valid_593163 = query.getOrDefault("creds-type")
  valid_593163 = validateParameter(valid_593163, JString, required = true,
                                 default = newJString("IAM"))
  if valid_593163 != nil:
    section.add "creds-type", valid_593163
  var valid_593164 = query.getOrDefault("user-arn")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "user-arn", valid_593164
  var valid_593165 = query.getOrDefault("session-lifetime")
  valid_593165 = validateParameter(valid_593165, JInt, required = false, default = nil)
  if valid_593165 != nil:
    section.add "session-lifetime", valid_593165
  var valid_593166 = query.getOrDefault("undo-redo-disabled")
  valid_593166 = validateParameter(valid_593166, JBool, required = false, default = nil)
  if valid_593166 != nil:
    section.add "undo-redo-disabled", valid_593166
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593167 = header.getOrDefault("X-Amz-Signature")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Signature", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Content-Sha256", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-Date")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-Date", valid_593169
  var valid_593170 = header.getOrDefault("X-Amz-Credential")
  valid_593170 = validateParameter(valid_593170, JString, required = false,
                                 default = nil)
  if valid_593170 != nil:
    section.add "X-Amz-Credential", valid_593170
  var valid_593171 = header.getOrDefault("X-Amz-Security-Token")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Security-Token", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Algorithm")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Algorithm", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-SignedHeaders", valid_593173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593174: Call_GetDashboardEmbedUrl_593144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a server-side embeddable URL and authorization code. Before this can work properly, first you need to configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/en_us/quicksight/latest/user/embedding.html"> Embedding Amazon QuickSight Dashboards</a>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p> <p> <b>CLI Sample:</b> </p> <p>Assume the role with permissions enabled for actions: <code>quickSight:RegisterUser</code> and <code>quicksight:GetDashboardEmbedURL</code>. You can use assume-role, assume-role-with-web-identity, or assume-role-with-saml. </p> <p> <code>aws sts assume-role --role-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --role-session-name embeddingsession</code> </p> <p>If the user does not exist in QuickSight, register the user:</p> <p> <code>aws quicksight register-user --aws-account-id 111122223333 --namespace default --identity-type IAM --iam-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --user-role READER --session-name "embeddingsession" --email user123@example.com --region us-east-1</code> </p> <p>Get the URL for the embedded dashboard</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type IAM</code> </p>
  ## 
  let valid = call_593174.validator(path, query, header, formData, body)
  let scheme = call_593174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593174.url(scheme.get, call_593174.host, call_593174.base,
                         call_593174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593174, url, valid)

proc call*(call_593175: Call_GetDashboardEmbedUrl_593144; AwsAccountId: string;
          DashboardId: string; resetDisabled: bool = false; credsType: string = "IAM";
          userArn: string = ""; sessionLifetime: int = 0; undoRedoDisabled: bool = false): Recallable =
  ## getDashboardEmbedUrl
  ## <p>Generates a server-side embeddable URL and authorization code. Before this can work properly, first you need to configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/en_us/quicksight/latest/user/embedding.html"> Embedding Amazon QuickSight Dashboards</a>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p> <p> <b>CLI Sample:</b> </p> <p>Assume the role with permissions enabled for actions: <code>quickSight:RegisterUser</code> and <code>quicksight:GetDashboardEmbedURL</code>. You can use assume-role, assume-role-with-web-identity, or assume-role-with-saml. </p> <p> <code>aws sts assume-role --role-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --role-session-name embeddingsession</code> </p> <p>If the user does not exist in QuickSight, register the user:</p> <p> <code>aws quicksight register-user --aws-account-id 111122223333 --namespace default --identity-type IAM --iam-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --user-role READER --session-name "embeddingsession" --email user123@example.com --region us-east-1</code> </p> <p>Get the URL for the embedded dashboard</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type IAM</code> </p>
  ##   resetDisabled: bool
  ##                : Remove the reset button on embedded dashboard. The default is FALSE, which allows the reset button.
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are embedding.
  ##   credsType: string (required)
  ##            : The authentication method the user uses to sign in (IAM only).
  ##   userArn: string
  ##          : <p>The Amazon QuickSight user's ARN, for use with <code>QUICKSIGHT</code> identity type. You can use this for any of the following:</p> <ul> <li> <p>Amazon QuickSight users in your account (readers, authors, or admins)</p> </li> <li> <p>AD users</p> </li> <li> <p>Invited non-federated users</p> </li> <li> <p>Federated IAM users</p> </li> <li> <p>Federated IAM role-based sessions</p> </li> </ul>
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to IAM policy
  ##   sessionLifetime: int
  ##                  : How many minutes the session is valid. The session lifetime must be between 15 and 600 minutes.
  ##   undoRedoDisabled: bool
  ##                   : Remove the undo/redo button on embedded dashboard. The default is FALSE, which enables the undo/redo button.
  var path_593176 = newJObject()
  var query_593177 = newJObject()
  add(query_593177, "reset-disabled", newJBool(resetDisabled))
  add(path_593176, "AwsAccountId", newJString(AwsAccountId))
  add(query_593177, "creds-type", newJString(credsType))
  add(query_593177, "user-arn", newJString(userArn))
  add(path_593176, "DashboardId", newJString(DashboardId))
  add(query_593177, "session-lifetime", newJInt(sessionLifetime))
  add(query_593177, "undo-redo-disabled", newJBool(undoRedoDisabled))
  result = call_593175.call(path_593176, query_593177, nil, nil, nil)

var getDashboardEmbedUrl* = Call_GetDashboardEmbedUrl_593144(
    name: "getDashboardEmbedUrl", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type",
    validator: validate_GetDashboardEmbedUrl_593145, base: "/",
    url: url_GetDashboardEmbedUrl_593146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMemberships_593178 = ref object of OpenApiRestCall_592364
proc url_ListGroupMemberships_593180(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListGroupMemberships_593179(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists member users in a group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a list of group member objects.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-group-memberships -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to see a membership list of.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_593181 = path.getOrDefault("GroupName")
  valid_593181 = validateParameter(valid_593181, JString, required = true,
                                 default = nil)
  if valid_593181 != nil:
    section.add "GroupName", valid_593181
  var valid_593182 = path.getOrDefault("AwsAccountId")
  valid_593182 = validateParameter(valid_593182, JString, required = true,
                                 default = nil)
  if valid_593182 != nil:
    section.add "AwsAccountId", valid_593182
  var valid_593183 = path.getOrDefault("Namespace")
  valid_593183 = validateParameter(valid_593183, JString, required = true,
                                 default = nil)
  if valid_593183 != nil:
    section.add "Namespace", valid_593183
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_593184 = query.getOrDefault("max-results")
  valid_593184 = validateParameter(valid_593184, JInt, required = false, default = nil)
  if valid_593184 != nil:
    section.add "max-results", valid_593184
  var valid_593185 = query.getOrDefault("next-token")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "next-token", valid_593185
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593186 = header.getOrDefault("X-Amz-Signature")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Signature", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Content-Sha256", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Date")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Date", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Credential")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Credential", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Security-Token")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Security-Token", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-Algorithm")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Algorithm", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-SignedHeaders", valid_593192
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593193: Call_ListGroupMemberships_593178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists member users in a group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a list of group member objects.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-group-memberships -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ## 
  let valid = call_593193.validator(path, query, header, formData, body)
  let scheme = call_593193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593193.url(scheme.get, call_593193.host, call_593193.base,
                         call_593193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593193, url, valid)

proc call*(call_593194: Call_ListGroupMemberships_593178; GroupName: string;
          AwsAccountId: string; Namespace: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGroupMemberships
  ## <p>Lists member users in a group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a list of group member objects.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-group-memberships -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to see a membership list of.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_593195 = newJObject()
  var query_593196 = newJObject()
  add(path_593195, "GroupName", newJString(GroupName))
  add(path_593195, "AwsAccountId", newJString(AwsAccountId))
  add(path_593195, "Namespace", newJString(Namespace))
  add(query_593196, "max-results", newJInt(maxResults))
  add(query_593196, "next-token", newJString(nextToken))
  result = call_593194.call(path_593195, query_593196, nil, nil, nil)

var listGroupMemberships* = Call_ListGroupMemberships_593178(
    name: "listGroupMemberships", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members",
    validator: validate_ListGroupMemberships_593179, base: "/",
    url: url_ListGroupMemberships_593180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserGroups_593197 = ref object of OpenApiRestCall_592364
proc url_ListUserGroups_593199(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListUserGroups_593198(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.</p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a one or more group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-user-groups -\-user-name=Pat -\-aws-account-id=111122223333 -\-namespace=default -\-region=us-east-1 </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_593200 = path.getOrDefault("AwsAccountId")
  valid_593200 = validateParameter(valid_593200, JString, required = true,
                                 default = nil)
  if valid_593200 != nil:
    section.add "AwsAccountId", valid_593200
  var valid_593201 = path.getOrDefault("Namespace")
  valid_593201 = validateParameter(valid_593201, JString, required = true,
                                 default = nil)
  if valid_593201 != nil:
    section.add "Namespace", valid_593201
  var valid_593202 = path.getOrDefault("UserName")
  valid_593202 = validateParameter(valid_593202, JString, required = true,
                                 default = nil)
  if valid_593202 != nil:
    section.add "UserName", valid_593202
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_593203 = query.getOrDefault("max-results")
  valid_593203 = validateParameter(valid_593203, JInt, required = false, default = nil)
  if valid_593203 != nil:
    section.add "max-results", valid_593203
  var valid_593204 = query.getOrDefault("next-token")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "next-token", valid_593204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593205 = header.getOrDefault("X-Amz-Signature")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-Signature", valid_593205
  var valid_593206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Content-Sha256", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Date")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Date", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Credential")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Credential", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Security-Token")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Security-Token", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Algorithm")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Algorithm", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-SignedHeaders", valid_593211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593212: Call_ListUserGroups_593197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.</p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a one or more group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-user-groups -\-user-name=Pat -\-aws-account-id=111122223333 -\-namespace=default -\-region=us-east-1 </code> </p>
  ## 
  let valid = call_593212.validator(path, query, header, formData, body)
  let scheme = call_593212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593212.url(scheme.get, call_593212.host, call_593212.base,
                         call_593212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593212, url, valid)

proc call*(call_593213: Call_ListUserGroups_593197; AwsAccountId: string;
          Namespace: string; UserName: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listUserGroups
  ## <p>Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.</p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>. </p> <p>The response is a one or more group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-user-groups -\-user-name=Pat -\-aws-account-id=111122223333 -\-namespace=default -\-region=us-east-1 </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_593214 = newJObject()
  var query_593215 = newJObject()
  add(path_593214, "AwsAccountId", newJString(AwsAccountId))
  add(path_593214, "Namespace", newJString(Namespace))
  add(path_593214, "UserName", newJString(UserName))
  add(query_593215, "max-results", newJInt(maxResults))
  add(query_593215, "next-token", newJString(nextToken))
  result = call_593213.call(path_593214, query_593215, nil, nil, nil)

var listUserGroups* = Call_ListUserGroups_593197(name: "listUserGroups",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups",
    validator: validate_ListUserGroups_593198, base: "/", url: url_ListUserGroups_593199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUser_593234 = ref object of OpenApiRestCall_592364
proc url_RegisterUser_593236(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_RegisterUser_593235(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>.</p> <p>The condition resource is the Amazon Resource Name (ARN) for the IAM user or role, and the session name. </p> <p>The condition keys are <code>quicksight:IamArn</code> and <code>quicksight:SessionName</code>. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight register-user -\-aws-account-id=111122223333 -\-namespace=default -\-email=pat@example.com -\-identity-type=IAM -\-user-role=AUTHOR -\-iam-arn=arn:aws:iam::111122223333:user/Pat </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_593237 = path.getOrDefault("AwsAccountId")
  valid_593237 = validateParameter(valid_593237, JString, required = true,
                                 default = nil)
  if valid_593237 != nil:
    section.add "AwsAccountId", valid_593237
  var valid_593238 = path.getOrDefault("Namespace")
  valid_593238 = validateParameter(valid_593238, JString, required = true,
                                 default = nil)
  if valid_593238 != nil:
    section.add "Namespace", valid_593238
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593239 = header.getOrDefault("X-Amz-Signature")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Signature", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Content-Sha256", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-Date")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Date", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Credential")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Credential", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Security-Token")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Security-Token", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Algorithm")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Algorithm", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-SignedHeaders", valid_593245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593247: Call_RegisterUser_593234; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>.</p> <p>The condition resource is the Amazon Resource Name (ARN) for the IAM user or role, and the session name. </p> <p>The condition keys are <code>quicksight:IamArn</code> and <code>quicksight:SessionName</code>. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight register-user -\-aws-account-id=111122223333 -\-namespace=default -\-email=pat@example.com -\-identity-type=IAM -\-user-role=AUTHOR -\-iam-arn=arn:aws:iam::111122223333:user/Pat </code> </p>
  ## 
  let valid = call_593247.validator(path, query, header, formData, body)
  let scheme = call_593247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593247.url(scheme.get, call_593247.host, call_593247.base,
                         call_593247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593247, url, valid)

proc call*(call_593248: Call_RegisterUser_593234; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## registerUser
  ## <p>Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>&lt;user-name&gt;</i> </code>.</p> <p>The condition resource is the Amazon Resource Name (ARN) for the IAM user or role, and the session name. </p> <p>The condition keys are <code>quicksight:IamArn</code> and <code>quicksight:SessionName</code>. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight register-user -\-aws-account-id=111122223333 -\-namespace=default -\-email=pat@example.com -\-identity-type=IAM -\-user-role=AUTHOR -\-iam-arn=arn:aws:iam::111122223333:user/Pat </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_593249 = newJObject()
  var body_593250 = newJObject()
  add(path_593249, "AwsAccountId", newJString(AwsAccountId))
  add(path_593249, "Namespace", newJString(Namespace))
  if body != nil:
    body_593250 = body
  result = call_593248.call(path_593249, nil, nil, nil, body_593250)

var registerUser* = Call_RegisterUser_593234(name: "registerUser",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
    validator: validate_RegisterUser_593235, base: "/", url: url_RegisterUser_593236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_593216 = ref object of OpenApiRestCall_592364
proc url_ListUsers_593218(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListUsers_593217(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of all of the Amazon QuickSight users belonging to this account. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>*</i> </code>.</p> <p>The response is a list of user objects, containing each user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-users --aws-account-id=111122223333 --namespace=default </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_593219 = path.getOrDefault("AwsAccountId")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = nil)
  if valid_593219 != nil:
    section.add "AwsAccountId", valid_593219
  var valid_593220 = path.getOrDefault("Namespace")
  valid_593220 = validateParameter(valid_593220, JString, required = true,
                                 default = nil)
  if valid_593220 != nil:
    section.add "Namespace", valid_593220
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_593221 = query.getOrDefault("max-results")
  valid_593221 = validateParameter(valid_593221, JInt, required = false, default = nil)
  if valid_593221 != nil:
    section.add "max-results", valid_593221
  var valid_593222 = query.getOrDefault("next-token")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "next-token", valid_593222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593223 = header.getOrDefault("X-Amz-Signature")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Signature", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Content-Sha256", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Date")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Date", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Credential")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Credential", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-Security-Token")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Security-Token", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Algorithm")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Algorithm", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-SignedHeaders", valid_593229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593230: Call_ListUsers_593216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all of the Amazon QuickSight users belonging to this account. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>*</i> </code>.</p> <p>The response is a list of user objects, containing each user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-users --aws-account-id=111122223333 --namespace=default </code> </p>
  ## 
  let valid = call_593230.validator(path, query, header, formData, body)
  let scheme = call_593230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593230.url(scheme.get, call_593230.host, call_593230.base,
                         call_593230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593230, url, valid)

proc call*(call_593231: Call_ListUsers_593216; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## <p>Returns a list of all of the Amazon QuickSight users belonging to this account. </p> <p>The permission resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:user/default/<i>*</i> </code>.</p> <p>The response is a list of user objects, containing each user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-users --aws-account-id=111122223333 --namespace=default </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_593232 = newJObject()
  var query_593233 = newJObject()
  add(path_593232, "AwsAccountId", newJString(AwsAccountId))
  add(path_593232, "Namespace", newJString(Namespace))
  add(query_593233, "max-results", newJInt(maxResults))
  add(query_593233, "next-token", newJString(nextToken))
  result = call_593231.call(path_593232, query_593233, nil, nil, nil)

var listUsers* = Call_ListUsers_593216(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
                                    validator: validate_ListUsers_593217,
                                    base: "/", url: url_ListUsers_593218,
                                    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
