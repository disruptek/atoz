
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2011-02-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearch/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
                           "us-east-1": "cloudsearch.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudsearch.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearch.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearch.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearch"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCreateDomain_592974 = ref object of OpenApiRestCall_592364
proc url_PostCreateDomain_592976(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDomain_592975(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_592977 = query.getOrDefault("Action")
  valid_592977 = validateParameter(valid_592977, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_592977 != nil:
    section.add "Action", valid_592977
  var valid_592978 = query.getOrDefault("Version")
  valid_592978 = validateParameter(valid_592978, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_592978 != nil:
    section.add "Version", valid_592978
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
  var valid_592979 = header.getOrDefault("X-Amz-Signature")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Signature", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Content-Sha256", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-Date")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Date", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Credential")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Credential", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Security-Token")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Security-Token", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Algorithm")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Algorithm", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-SignedHeaders", valid_592985
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_592986 = formData.getOrDefault("DomainName")
  valid_592986 = validateParameter(valid_592986, JString, required = true,
                                 default = nil)
  if valid_592986 != nil:
    section.add "DomainName", valid_592986
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592987: Call_PostCreateDomain_592974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_592987.validator(path, query, header, formData, body)
  let scheme = call_592987.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592987.url(scheme.get, call_592987.host, call_592987.base,
                         call_592987.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592987, url, valid)

proc call*(call_592988: Call_PostCreateDomain_592974; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592989 = newJObject()
  var formData_592990 = newJObject()
  add(formData_592990, "DomainName", newJString(DomainName))
  add(query_592989, "Action", newJString(Action))
  add(query_592989, "Version", newJString(Version))
  result = call_592988.call(nil, query_592989, nil, formData_592990, nil)

var postCreateDomain* = Call_PostCreateDomain_592974(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_592975,
    base: "/", url: url_PostCreateDomain_592976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_592703 = ref object of OpenApiRestCall_592364
proc url_GetCreateDomain_592705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDomain_592704(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_592817 = query.getOrDefault("DomainName")
  valid_592817 = validateParameter(valid_592817, JString, required = true,
                                 default = nil)
  if valid_592817 != nil:
    section.add "DomainName", valid_592817
  var valid_592831 = query.getOrDefault("Action")
  valid_592831 = validateParameter(valid_592831, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_592831 != nil:
    section.add "Action", valid_592831
  var valid_592832 = query.getOrDefault("Version")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_592832 != nil:
    section.add "Version", valid_592832
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
  var valid_592833 = header.getOrDefault("X-Amz-Signature")
  valid_592833 = validateParameter(valid_592833, JString, required = false,
                                 default = nil)
  if valid_592833 != nil:
    section.add "X-Amz-Signature", valid_592833
  var valid_592834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "X-Amz-Content-Sha256", valid_592834
  var valid_592835 = header.getOrDefault("X-Amz-Date")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Date", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Credential")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Credential", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Security-Token")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Security-Token", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Algorithm")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Algorithm", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-SignedHeaders", valid_592839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592862: Call_GetCreateDomain_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_592862.validator(path, query, header, formData, body)
  let scheme = call_592862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592862.url(scheme.get, call_592862.host, call_592862.base,
                         call_592862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592862, url, valid)

proc call*(call_592933: Call_GetCreateDomain_592703; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_592934 = newJObject()
  add(query_592934, "DomainName", newJString(DomainName))
  add(query_592934, "Action", newJString(Action))
  add(query_592934, "Version", newJString(Version))
  result = call_592933.call(nil, query_592934, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_592703(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_592704,
    base: "/", url: url_GetCreateDomain_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_593013 = ref object of OpenApiRestCall_592364
proc url_PostDefineIndexField_593015(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineIndexField_593014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593016 = query.getOrDefault("Action")
  valid_593016 = validateParameter(valid_593016, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_593016 != nil:
    section.add "Action", valid_593016
  var valid_593017 = query.getOrDefault("Version")
  valid_593017 = validateParameter(valid_593017, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593017 != nil:
    section.add "Version", valid_593017
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
  ## parameters in `formData` object:
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  var valid_593025 = formData.getOrDefault("IndexField.UIntOptions")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "IndexField.UIntOptions", valid_593025
  var valid_593026 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_593026 = validateParameter(valid_593026, JArray, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "IndexField.SourceAttributes", valid_593026
  var valid_593027 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "IndexField.IndexFieldType", valid_593027
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593028 = formData.getOrDefault("DomainName")
  valid_593028 = validateParameter(valid_593028, JString, required = true,
                                 default = nil)
  if valid_593028 != nil:
    section.add "DomainName", valid_593028
  var valid_593029 = formData.getOrDefault("IndexField.TextOptions")
  valid_593029 = validateParameter(valid_593029, JString, required = false,
                                 default = nil)
  if valid_593029 != nil:
    section.add "IndexField.TextOptions", valid_593029
  var valid_593030 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "IndexField.LiteralOptions", valid_593030
  var valid_593031 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "IndexField.IndexFieldName", valid_593031
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593032: Call_PostDefineIndexField_593013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_593032.validator(path, query, header, formData, body)
  let scheme = call_593032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593032.url(scheme.get, call_593032.host, call_593032.base,
                         call_593032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593032, url, valid)

proc call*(call_593033: Call_PostDefineIndexField_593013; DomainName: string;
          IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          IndexFieldIndexFieldType: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; Version: string = "2011-02-01"): Recallable =
  ## postDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_593034 = newJObject()
  var formData_593035 = newJObject()
  add(formData_593035, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    formData_593035.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(formData_593035, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_593035, "DomainName", newJString(DomainName))
  add(formData_593035, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_593035, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_593034, "Action", newJString(Action))
  add(formData_593035, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_593034, "Version", newJString(Version))
  result = call_593033.call(nil, query_593034, nil, formData_593035, nil)

var postDefineIndexField* = Call_PostDefineIndexField_593013(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_593014, base: "/",
    url: url_PostDefineIndexField_593015, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_592991 = ref object of OpenApiRestCall_592364
proc url_GetDefineIndexField_592993(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineIndexField_592992(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: JString (required)
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: JString (required)
  section = newJObject()
  var valid_592994 = query.getOrDefault("IndexField.TextOptions")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "IndexField.TextOptions", valid_592994
  var valid_592995 = query.getOrDefault("IndexField.IndexFieldType")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "IndexField.IndexFieldType", valid_592995
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_592996 = query.getOrDefault("DomainName")
  valid_592996 = validateParameter(valid_592996, JString, required = true,
                                 default = nil)
  if valid_592996 != nil:
    section.add "DomainName", valid_592996
  var valid_592997 = query.getOrDefault("IndexField.IndexFieldName")
  valid_592997 = validateParameter(valid_592997, JString, required = false,
                                 default = nil)
  if valid_592997 != nil:
    section.add "IndexField.IndexFieldName", valid_592997
  var valid_592998 = query.getOrDefault("IndexField.UIntOptions")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "IndexField.UIntOptions", valid_592998
  var valid_592999 = query.getOrDefault("IndexField.SourceAttributes")
  valid_592999 = validateParameter(valid_592999, JArray, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "IndexField.SourceAttributes", valid_592999
  var valid_593000 = query.getOrDefault("Action")
  valid_593000 = validateParameter(valid_593000, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_593000 != nil:
    section.add "Action", valid_593000
  var valid_593001 = query.getOrDefault("IndexField.LiteralOptions")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "IndexField.LiteralOptions", valid_593001
  var valid_593002 = query.getOrDefault("Version")
  valid_593002 = validateParameter(valid_593002, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593002 != nil:
    section.add "Version", valid_593002
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
  var valid_593003 = header.getOrDefault("X-Amz-Signature")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Signature", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Content-Sha256", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Date")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Date", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Credential")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Credential", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Security-Token")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Security-Token", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Algorithm")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Algorithm", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-SignedHeaders", valid_593009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593010: Call_GetDefineIndexField_592991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_593010.validator(path, query, header, formData, body)
  let scheme = call_593010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593010.url(scheme.get, call_593010.host, call_593010.base,
                         call_593010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593010, url, valid)

proc call*(call_593011: Call_GetDefineIndexField_592991; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldIndexFieldType: string = "";
          IndexFieldIndexFieldName: string = ""; IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          Action: string = "DefineIndexField";
          IndexFieldLiteralOptions: string = ""; Version: string = "2011-02-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: string (required)
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: string (required)
  var query_593012 = newJObject()
  add(query_593012, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_593012, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_593012, "DomainName", newJString(DomainName))
  add(query_593012, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_593012, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    query_593012.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_593012, "Action", newJString(Action))
  add(query_593012, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_593012, "Version", newJString(Version))
  result = call_593011.call(nil, query_593012, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_592991(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_592992, base: "/",
    url: url_GetDefineIndexField_592993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_593054 = ref object of OpenApiRestCall_592364
proc url_PostDefineRankExpression_593056(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDefineRankExpression_593055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593057 = query.getOrDefault("Action")
  valid_593057 = validateParameter(valid_593057, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_593057 != nil:
    section.add "Action", valid_593057
  var valid_593058 = query.getOrDefault("Version")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593058 != nil:
    section.add "Version", valid_593058
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
  var valid_593059 = header.getOrDefault("X-Amz-Signature")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Signature", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Content-Sha256", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Date")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Date", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Credential")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Credential", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Security-Token")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Security-Token", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Algorithm")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Algorithm", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-SignedHeaders", valid_593065
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_593066 = formData.getOrDefault("RankExpression.RankName")
  valid_593066 = validateParameter(valid_593066, JString, required = false,
                                 default = nil)
  if valid_593066 != nil:
    section.add "RankExpression.RankName", valid_593066
  var valid_593067 = formData.getOrDefault("RankExpression.RankExpression")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "RankExpression.RankExpression", valid_593067
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593068 = formData.getOrDefault("DomainName")
  valid_593068 = validateParameter(valid_593068, JString, required = true,
                                 default = nil)
  if valid_593068 != nil:
    section.add "DomainName", valid_593068
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593069: Call_PostDefineRankExpression_593054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_593069.validator(path, query, header, formData, body)
  let scheme = call_593069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593069.url(scheme.get, call_593069.host, call_593069.base,
                         call_593069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593069, url, valid)

proc call*(call_593070: Call_PostDefineRankExpression_593054; DomainName: string;
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = "";
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593071 = newJObject()
  var formData_593072 = newJObject()
  add(formData_593072, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_593072, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(formData_593072, "DomainName", newJString(DomainName))
  add(query_593071, "Action", newJString(Action))
  add(query_593071, "Version", newJString(Version))
  result = call_593070.call(nil, query_593071, nil, formData_593072, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_593054(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_593055, base: "/",
    url: url_PostDefineRankExpression_593056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_593036 = ref object of OpenApiRestCall_592364
proc url_GetDefineRankExpression_593038(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDefineRankExpression_593037(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593039 = query.getOrDefault("DomainName")
  valid_593039 = validateParameter(valid_593039, JString, required = true,
                                 default = nil)
  if valid_593039 != nil:
    section.add "DomainName", valid_593039
  var valid_593040 = query.getOrDefault("Action")
  valid_593040 = validateParameter(valid_593040, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_593040 != nil:
    section.add "Action", valid_593040
  var valid_593041 = query.getOrDefault("Version")
  valid_593041 = validateParameter(valid_593041, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593041 != nil:
    section.add "Version", valid_593041
  var valid_593042 = query.getOrDefault("RankExpression.RankName")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "RankExpression.RankName", valid_593042
  var valid_593043 = query.getOrDefault("RankExpression.RankExpression")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "RankExpression.RankExpression", valid_593043
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
  var valid_593044 = header.getOrDefault("X-Amz-Signature")
  valid_593044 = validateParameter(valid_593044, JString, required = false,
                                 default = nil)
  if valid_593044 != nil:
    section.add "X-Amz-Signature", valid_593044
  var valid_593045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Content-Sha256", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Date")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Date", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Credential")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Credential", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Security-Token")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Security-Token", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Algorithm")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Algorithm", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-SignedHeaders", valid_593050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593051: Call_GetDefineRankExpression_593036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_593051.validator(path, query, header, formData, body)
  let scheme = call_593051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593051.url(scheme.get, call_593051.host, call_593051.base,
                         call_593051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593051, url, valid)

proc call*(call_593052: Call_GetDefineRankExpression_593036; DomainName: string;
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01";
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = ""): Recallable =
  ## getDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  var query_593053 = newJObject()
  add(query_593053, "DomainName", newJString(DomainName))
  add(query_593053, "Action", newJString(Action))
  add(query_593053, "Version", newJString(Version))
  add(query_593053, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_593053, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  result = call_593052.call(nil, query_593053, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_593036(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_593037, base: "/",
    url: url_GetDefineRankExpression_593038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_593089 = ref object of OpenApiRestCall_592364
proc url_PostDeleteDomain_593091(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDomain_593090(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593092 = query.getOrDefault("Action")
  valid_593092 = validateParameter(valid_593092, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_593092 != nil:
    section.add "Action", valid_593092
  var valid_593093 = query.getOrDefault("Version")
  valid_593093 = validateParameter(valid_593093, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593093 != nil:
    section.add "Version", valid_593093
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
  var valid_593094 = header.getOrDefault("X-Amz-Signature")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Signature", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-Content-Sha256", valid_593095
  var valid_593096 = header.getOrDefault("X-Amz-Date")
  valid_593096 = validateParameter(valid_593096, JString, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "X-Amz-Date", valid_593096
  var valid_593097 = header.getOrDefault("X-Amz-Credential")
  valid_593097 = validateParameter(valid_593097, JString, required = false,
                                 default = nil)
  if valid_593097 != nil:
    section.add "X-Amz-Credential", valid_593097
  var valid_593098 = header.getOrDefault("X-Amz-Security-Token")
  valid_593098 = validateParameter(valid_593098, JString, required = false,
                                 default = nil)
  if valid_593098 != nil:
    section.add "X-Amz-Security-Token", valid_593098
  var valid_593099 = header.getOrDefault("X-Amz-Algorithm")
  valid_593099 = validateParameter(valid_593099, JString, required = false,
                                 default = nil)
  if valid_593099 != nil:
    section.add "X-Amz-Algorithm", valid_593099
  var valid_593100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593100 = validateParameter(valid_593100, JString, required = false,
                                 default = nil)
  if valid_593100 != nil:
    section.add "X-Amz-SignedHeaders", valid_593100
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593101 = formData.getOrDefault("DomainName")
  valid_593101 = validateParameter(valid_593101, JString, required = true,
                                 default = nil)
  if valid_593101 != nil:
    section.add "DomainName", valid_593101
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593102: Call_PostDeleteDomain_593089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_593102.validator(path, query, header, formData, body)
  let scheme = call_593102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593102.url(scheme.get, call_593102.host, call_593102.base,
                         call_593102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593102, url, valid)

proc call*(call_593103: Call_PostDeleteDomain_593089; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593104 = newJObject()
  var formData_593105 = newJObject()
  add(formData_593105, "DomainName", newJString(DomainName))
  add(query_593104, "Action", newJString(Action))
  add(query_593104, "Version", newJString(Version))
  result = call_593103.call(nil, query_593104, nil, formData_593105, nil)

var postDeleteDomain* = Call_PostDeleteDomain_593089(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_593090,
    base: "/", url: url_PostDeleteDomain_593091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_593073 = ref object of OpenApiRestCall_592364
proc url_GetDeleteDomain_593075(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDomain_593074(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593076 = query.getOrDefault("DomainName")
  valid_593076 = validateParameter(valid_593076, JString, required = true,
                                 default = nil)
  if valid_593076 != nil:
    section.add "DomainName", valid_593076
  var valid_593077 = query.getOrDefault("Action")
  valid_593077 = validateParameter(valid_593077, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_593077 != nil:
    section.add "Action", valid_593077
  var valid_593078 = query.getOrDefault("Version")
  valid_593078 = validateParameter(valid_593078, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593078 != nil:
    section.add "Version", valid_593078
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
  var valid_593079 = header.getOrDefault("X-Amz-Signature")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-Signature", valid_593079
  var valid_593080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593080 = validateParameter(valid_593080, JString, required = false,
                                 default = nil)
  if valid_593080 != nil:
    section.add "X-Amz-Content-Sha256", valid_593080
  var valid_593081 = header.getOrDefault("X-Amz-Date")
  valid_593081 = validateParameter(valid_593081, JString, required = false,
                                 default = nil)
  if valid_593081 != nil:
    section.add "X-Amz-Date", valid_593081
  var valid_593082 = header.getOrDefault("X-Amz-Credential")
  valid_593082 = validateParameter(valid_593082, JString, required = false,
                                 default = nil)
  if valid_593082 != nil:
    section.add "X-Amz-Credential", valid_593082
  var valid_593083 = header.getOrDefault("X-Amz-Security-Token")
  valid_593083 = validateParameter(valid_593083, JString, required = false,
                                 default = nil)
  if valid_593083 != nil:
    section.add "X-Amz-Security-Token", valid_593083
  var valid_593084 = header.getOrDefault("X-Amz-Algorithm")
  valid_593084 = validateParameter(valid_593084, JString, required = false,
                                 default = nil)
  if valid_593084 != nil:
    section.add "X-Amz-Algorithm", valid_593084
  var valid_593085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593085 = validateParameter(valid_593085, JString, required = false,
                                 default = nil)
  if valid_593085 != nil:
    section.add "X-Amz-SignedHeaders", valid_593085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593086: Call_GetDeleteDomain_593073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_593086.validator(path, query, header, formData, body)
  let scheme = call_593086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593086.url(scheme.get, call_593086.host, call_593086.base,
                         call_593086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593086, url, valid)

proc call*(call_593087: Call_GetDeleteDomain_593073; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593088 = newJObject()
  add(query_593088, "DomainName", newJString(DomainName))
  add(query_593088, "Action", newJString(Action))
  add(query_593088, "Version", newJString(Version))
  result = call_593087.call(nil, query_593088, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_593073(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_593074,
    base: "/", url: url_GetDeleteDomain_593075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_593123 = ref object of OpenApiRestCall_592364
proc url_PostDeleteIndexField_593125(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteIndexField_593124(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593126 = query.getOrDefault("Action")
  valid_593126 = validateParameter(valid_593126, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_593126 != nil:
    section.add "Action", valid_593126
  var valid_593127 = query.getOrDefault("Version")
  valid_593127 = validateParameter(valid_593127, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593127 != nil:
    section.add "Version", valid_593127
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
  var valid_593128 = header.getOrDefault("X-Amz-Signature")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Signature", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Content-Sha256", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Date")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Date", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Credential")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Credential", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Security-Token")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Security-Token", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Algorithm")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Algorithm", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-SignedHeaders", valid_593134
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593135 = formData.getOrDefault("DomainName")
  valid_593135 = validateParameter(valid_593135, JString, required = true,
                                 default = nil)
  if valid_593135 != nil:
    section.add "DomainName", valid_593135
  var valid_593136 = formData.getOrDefault("IndexFieldName")
  valid_593136 = validateParameter(valid_593136, JString, required = true,
                                 default = nil)
  if valid_593136 != nil:
    section.add "IndexFieldName", valid_593136
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593137: Call_PostDeleteIndexField_593123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_593137.validator(path, query, header, formData, body)
  let scheme = call_593137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593137.url(scheme.get, call_593137.host, call_593137.base,
                         call_593137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593137, url, valid)

proc call*(call_593138: Call_PostDeleteIndexField_593123; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593139 = newJObject()
  var formData_593140 = newJObject()
  add(formData_593140, "DomainName", newJString(DomainName))
  add(formData_593140, "IndexFieldName", newJString(IndexFieldName))
  add(query_593139, "Action", newJString(Action))
  add(query_593139, "Version", newJString(Version))
  result = call_593138.call(nil, query_593139, nil, formData_593140, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_593123(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_593124, base: "/",
    url: url_PostDeleteIndexField_593125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_593106 = ref object of OpenApiRestCall_592364
proc url_GetDeleteIndexField_593108(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteIndexField_593107(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593109 = query.getOrDefault("DomainName")
  valid_593109 = validateParameter(valid_593109, JString, required = true,
                                 default = nil)
  if valid_593109 != nil:
    section.add "DomainName", valid_593109
  var valid_593110 = query.getOrDefault("Action")
  valid_593110 = validateParameter(valid_593110, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_593110 != nil:
    section.add "Action", valid_593110
  var valid_593111 = query.getOrDefault("IndexFieldName")
  valid_593111 = validateParameter(valid_593111, JString, required = true,
                                 default = nil)
  if valid_593111 != nil:
    section.add "IndexFieldName", valid_593111
  var valid_593112 = query.getOrDefault("Version")
  valid_593112 = validateParameter(valid_593112, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593112 != nil:
    section.add "Version", valid_593112
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
  var valid_593113 = header.getOrDefault("X-Amz-Signature")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Signature", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Content-Sha256", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Date")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Date", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Credential")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Credential", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Security-Token")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Security-Token", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Algorithm")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Algorithm", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-SignedHeaders", valid_593119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593120: Call_GetDeleteIndexField_593106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_593120.validator(path, query, header, formData, body)
  let scheme = call_593120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593120.url(scheme.get, call_593120.host, call_593120.base,
                         call_593120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593120, url, valid)

proc call*(call_593121: Call_GetDeleteIndexField_593106; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_593122 = newJObject()
  add(query_593122, "DomainName", newJString(DomainName))
  add(query_593122, "Action", newJString(Action))
  add(query_593122, "IndexFieldName", newJString(IndexFieldName))
  add(query_593122, "Version", newJString(Version))
  result = call_593121.call(nil, query_593122, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_593106(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_593107, base: "/",
    url: url_GetDeleteIndexField_593108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_593158 = ref object of OpenApiRestCall_592364
proc url_PostDeleteRankExpression_593160(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteRankExpression_593159(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593161 = query.getOrDefault("Action")
  valid_593161 = validateParameter(valid_593161, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_593161 != nil:
    section.add "Action", valid_593161
  var valid_593162 = query.getOrDefault("Version")
  valid_593162 = validateParameter(valid_593162, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593162 != nil:
    section.add "Version", valid_593162
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
  var valid_593163 = header.getOrDefault("X-Amz-Signature")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Signature", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Content-Sha256", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Date")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Date", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Credential")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Credential", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Security-Token")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Security-Token", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Algorithm")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Algorithm", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-SignedHeaders", valid_593169
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RankName` field"
  var valid_593170 = formData.getOrDefault("RankName")
  valid_593170 = validateParameter(valid_593170, JString, required = true,
                                 default = nil)
  if valid_593170 != nil:
    section.add "RankName", valid_593170
  var valid_593171 = formData.getOrDefault("DomainName")
  valid_593171 = validateParameter(valid_593171, JString, required = true,
                                 default = nil)
  if valid_593171 != nil:
    section.add "DomainName", valid_593171
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593172: Call_PostDeleteRankExpression_593158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_593172.validator(path, query, header, formData, body)
  let scheme = call_593172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593172.url(scheme.get, call_593172.host, call_593172.base,
                         call_593172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593172, url, valid)

proc call*(call_593173: Call_PostDeleteRankExpression_593158; RankName: string;
          DomainName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593174 = newJObject()
  var formData_593175 = newJObject()
  add(formData_593175, "RankName", newJString(RankName))
  add(formData_593175, "DomainName", newJString(DomainName))
  add(query_593174, "Action", newJString(Action))
  add(query_593174, "Version", newJString(Version))
  result = call_593173.call(nil, query_593174, nil, formData_593175, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_593158(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_593159, base: "/",
    url: url_PostDeleteRankExpression_593160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_593141 = ref object of OpenApiRestCall_592364
proc url_GetDeleteRankExpression_593143(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteRankExpression_593142(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593144 = query.getOrDefault("DomainName")
  valid_593144 = validateParameter(valid_593144, JString, required = true,
                                 default = nil)
  if valid_593144 != nil:
    section.add "DomainName", valid_593144
  var valid_593145 = query.getOrDefault("RankName")
  valid_593145 = validateParameter(valid_593145, JString, required = true,
                                 default = nil)
  if valid_593145 != nil:
    section.add "RankName", valid_593145
  var valid_593146 = query.getOrDefault("Action")
  valid_593146 = validateParameter(valid_593146, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_593146 != nil:
    section.add "Action", valid_593146
  var valid_593147 = query.getOrDefault("Version")
  valid_593147 = validateParameter(valid_593147, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593147 != nil:
    section.add "Version", valid_593147
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
  var valid_593148 = header.getOrDefault("X-Amz-Signature")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Signature", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Content-Sha256", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-Date")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-Date", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Credential")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Credential", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Security-Token")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Security-Token", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-Algorithm")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-Algorithm", valid_593153
  var valid_593154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "X-Amz-SignedHeaders", valid_593154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593155: Call_GetDeleteRankExpression_593141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_593155.validator(path, query, header, formData, body)
  let scheme = call_593155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593155.url(scheme.get, call_593155.host, call_593155.base,
                         call_593155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593155, url, valid)

proc call*(call_593156: Call_GetDeleteRankExpression_593141; DomainName: string;
          RankName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593157 = newJObject()
  add(query_593157, "DomainName", newJString(DomainName))
  add(query_593157, "RankName", newJString(RankName))
  add(query_593157, "Action", newJString(Action))
  add(query_593157, "Version", newJString(Version))
  result = call_593156.call(nil, query_593157, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_593141(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_593142, base: "/",
    url: url_GetDeleteRankExpression_593143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_593192 = ref object of OpenApiRestCall_592364
proc url_PostDescribeAvailabilityOptions_593194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAvailabilityOptions_593193(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593195 = query.getOrDefault("Action")
  valid_593195 = validateParameter(valid_593195, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_593195 != nil:
    section.add "Action", valid_593195
  var valid_593196 = query.getOrDefault("Version")
  valid_593196 = validateParameter(valid_593196, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593196 != nil:
    section.add "Version", valid_593196
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
  var valid_593197 = header.getOrDefault("X-Amz-Signature")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-Signature", valid_593197
  var valid_593198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593198 = validateParameter(valid_593198, JString, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "X-Amz-Content-Sha256", valid_593198
  var valid_593199 = header.getOrDefault("X-Amz-Date")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Date", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Credential")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Credential", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Security-Token")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Security-Token", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Algorithm")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Algorithm", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-SignedHeaders", valid_593203
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593204 = formData.getOrDefault("DomainName")
  valid_593204 = validateParameter(valid_593204, JString, required = true,
                                 default = nil)
  if valid_593204 != nil:
    section.add "DomainName", valid_593204
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593205: Call_PostDescribeAvailabilityOptions_593192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593205.validator(path, query, header, formData, body)
  let scheme = call_593205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593205.url(scheme.get, call_593205.host, call_593205.base,
                         call_593205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593205, url, valid)

proc call*(call_593206: Call_PostDescribeAvailabilityOptions_593192;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593207 = newJObject()
  var formData_593208 = newJObject()
  add(formData_593208, "DomainName", newJString(DomainName))
  add(query_593207, "Action", newJString(Action))
  add(query_593207, "Version", newJString(Version))
  result = call_593206.call(nil, query_593207, nil, formData_593208, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_593192(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_593193, base: "/",
    url: url_PostDescribeAvailabilityOptions_593194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_593176 = ref object of OpenApiRestCall_592364
proc url_GetDescribeAvailabilityOptions_593178(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAvailabilityOptions_593177(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593179 = query.getOrDefault("DomainName")
  valid_593179 = validateParameter(valid_593179, JString, required = true,
                                 default = nil)
  if valid_593179 != nil:
    section.add "DomainName", valid_593179
  var valid_593180 = query.getOrDefault("Action")
  valid_593180 = validateParameter(valid_593180, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_593180 != nil:
    section.add "Action", valid_593180
  var valid_593181 = query.getOrDefault("Version")
  valid_593181 = validateParameter(valid_593181, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593181 != nil:
    section.add "Version", valid_593181
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
  var valid_593182 = header.getOrDefault("X-Amz-Signature")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Signature", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Content-Sha256", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-Date")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-Date", valid_593184
  var valid_593185 = header.getOrDefault("X-Amz-Credential")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Credential", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Security-Token")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Security-Token", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Algorithm")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Algorithm", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-SignedHeaders", valid_593188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593189: Call_GetDescribeAvailabilityOptions_593176; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593189.validator(path, query, header, formData, body)
  let scheme = call_593189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593189.url(scheme.get, call_593189.host, call_593189.base,
                         call_593189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593189, url, valid)

proc call*(call_593190: Call_GetDescribeAvailabilityOptions_593176;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593191 = newJObject()
  add(query_593191, "DomainName", newJString(DomainName))
  add(query_593191, "Action", newJString(Action))
  add(query_593191, "Version", newJString(Version))
  result = call_593190.call(nil, query_593191, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_593176(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_593177, base: "/",
    url: url_GetDescribeAvailabilityOptions_593178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_593225 = ref object of OpenApiRestCall_592364
proc url_PostDescribeDefaultSearchField_593227(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDefaultSearchField_593226(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593228 = query.getOrDefault("Action")
  valid_593228 = validateParameter(valid_593228, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_593228 != nil:
    section.add "Action", valid_593228
  var valid_593229 = query.getOrDefault("Version")
  valid_593229 = validateParameter(valid_593229, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593229 != nil:
    section.add "Version", valid_593229
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
  var valid_593230 = header.getOrDefault("X-Amz-Signature")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Signature", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Content-Sha256", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Date")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Date", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-Credential")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-Credential", valid_593233
  var valid_593234 = header.getOrDefault("X-Amz-Security-Token")
  valid_593234 = validateParameter(valid_593234, JString, required = false,
                                 default = nil)
  if valid_593234 != nil:
    section.add "X-Amz-Security-Token", valid_593234
  var valid_593235 = header.getOrDefault("X-Amz-Algorithm")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Algorithm", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-SignedHeaders", valid_593236
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593237 = formData.getOrDefault("DomainName")
  valid_593237 = validateParameter(valid_593237, JString, required = true,
                                 default = nil)
  if valid_593237 != nil:
    section.add "DomainName", valid_593237
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593238: Call_PostDescribeDefaultSearchField_593225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_593238.validator(path, query, header, formData, body)
  let scheme = call_593238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593238.url(scheme.get, call_593238.host, call_593238.base,
                         call_593238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593238, url, valid)

proc call*(call_593239: Call_PostDescribeDefaultSearchField_593225;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593240 = newJObject()
  var formData_593241 = newJObject()
  add(formData_593241, "DomainName", newJString(DomainName))
  add(query_593240, "Action", newJString(Action))
  add(query_593240, "Version", newJString(Version))
  result = call_593239.call(nil, query_593240, nil, formData_593241, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_593225(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_593226, base: "/",
    url: url_PostDescribeDefaultSearchField_593227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_593209 = ref object of OpenApiRestCall_592364
proc url_GetDescribeDefaultSearchField_593211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDefaultSearchField_593210(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593212 = query.getOrDefault("DomainName")
  valid_593212 = validateParameter(valid_593212, JString, required = true,
                                 default = nil)
  if valid_593212 != nil:
    section.add "DomainName", valid_593212
  var valid_593213 = query.getOrDefault("Action")
  valid_593213 = validateParameter(valid_593213, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_593213 != nil:
    section.add "Action", valid_593213
  var valid_593214 = query.getOrDefault("Version")
  valid_593214 = validateParameter(valid_593214, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593214 != nil:
    section.add "Version", valid_593214
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
  var valid_593215 = header.getOrDefault("X-Amz-Signature")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Signature", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Content-Sha256", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Date")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Date", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Credential")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Credential", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-Security-Token")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-Security-Token", valid_593219
  var valid_593220 = header.getOrDefault("X-Amz-Algorithm")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Algorithm", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-SignedHeaders", valid_593221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593222: Call_GetDescribeDefaultSearchField_593209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_593222.validator(path, query, header, formData, body)
  let scheme = call_593222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593222.url(scheme.get, call_593222.host, call_593222.base,
                         call_593222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593222, url, valid)

proc call*(call_593223: Call_GetDescribeDefaultSearchField_593209;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593224 = newJObject()
  add(query_593224, "DomainName", newJString(DomainName))
  add(query_593224, "Action", newJString(Action))
  add(query_593224, "Version", newJString(Version))
  result = call_593223.call(nil, query_593224, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_593209(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_593210, base: "/",
    url: url_GetDescribeDefaultSearchField_593211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_593258 = ref object of OpenApiRestCall_592364
proc url_PostDescribeDomains_593260(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDomains_593259(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593261 = query.getOrDefault("Action")
  valid_593261 = validateParameter(valid_593261, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_593261 != nil:
    section.add "Action", valid_593261
  var valid_593262 = query.getOrDefault("Version")
  valid_593262 = validateParameter(valid_593262, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593262 != nil:
    section.add "Version", valid_593262
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
  var valid_593263 = header.getOrDefault("X-Amz-Signature")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-Signature", valid_593263
  var valid_593264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593264 = validateParameter(valid_593264, JString, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "X-Amz-Content-Sha256", valid_593264
  var valid_593265 = header.getOrDefault("X-Amz-Date")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "X-Amz-Date", valid_593265
  var valid_593266 = header.getOrDefault("X-Amz-Credential")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "X-Amz-Credential", valid_593266
  var valid_593267 = header.getOrDefault("X-Amz-Security-Token")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "X-Amz-Security-Token", valid_593267
  var valid_593268 = header.getOrDefault("X-Amz-Algorithm")
  valid_593268 = validateParameter(valid_593268, JString, required = false,
                                 default = nil)
  if valid_593268 != nil:
    section.add "X-Amz-Algorithm", valid_593268
  var valid_593269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "X-Amz-SignedHeaders", valid_593269
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_593270 = formData.getOrDefault("DomainNames")
  valid_593270 = validateParameter(valid_593270, JArray, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "DomainNames", valid_593270
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593271: Call_PostDescribeDomains_593258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_593271.validator(path, query, header, formData, body)
  let scheme = call_593271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593271.url(scheme.get, call_593271.host, call_593271.base,
                         call_593271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593271, url, valid)

proc call*(call_593272: Call_PostDescribeDomains_593258;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593273 = newJObject()
  var formData_593274 = newJObject()
  if DomainNames != nil:
    formData_593274.add "DomainNames", DomainNames
  add(query_593273, "Action", newJString(Action))
  add(query_593273, "Version", newJString(Version))
  result = call_593272.call(nil, query_593273, nil, formData_593274, nil)

var postDescribeDomains* = Call_PostDescribeDomains_593258(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_593259, base: "/",
    url: url_PostDescribeDomains_593260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_593242 = ref object of OpenApiRestCall_592364
proc url_GetDescribeDomains_593244(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDomains_593243(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_593245 = query.getOrDefault("DomainNames")
  valid_593245 = validateParameter(valid_593245, JArray, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "DomainNames", valid_593245
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593246 = query.getOrDefault("Action")
  valid_593246 = validateParameter(valid_593246, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_593246 != nil:
    section.add "Action", valid_593246
  var valid_593247 = query.getOrDefault("Version")
  valid_593247 = validateParameter(valid_593247, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593247 != nil:
    section.add "Version", valid_593247
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
  var valid_593248 = header.getOrDefault("X-Amz-Signature")
  valid_593248 = validateParameter(valid_593248, JString, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "X-Amz-Signature", valid_593248
  var valid_593249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "X-Amz-Content-Sha256", valid_593249
  var valid_593250 = header.getOrDefault("X-Amz-Date")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "X-Amz-Date", valid_593250
  var valid_593251 = header.getOrDefault("X-Amz-Credential")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "X-Amz-Credential", valid_593251
  var valid_593252 = header.getOrDefault("X-Amz-Security-Token")
  valid_593252 = validateParameter(valid_593252, JString, required = false,
                                 default = nil)
  if valid_593252 != nil:
    section.add "X-Amz-Security-Token", valid_593252
  var valid_593253 = header.getOrDefault("X-Amz-Algorithm")
  valid_593253 = validateParameter(valid_593253, JString, required = false,
                                 default = nil)
  if valid_593253 != nil:
    section.add "X-Amz-Algorithm", valid_593253
  var valid_593254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593254 = validateParameter(valid_593254, JString, required = false,
                                 default = nil)
  if valid_593254 != nil:
    section.add "X-Amz-SignedHeaders", valid_593254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593255: Call_GetDescribeDomains_593242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_593255.validator(path, query, header, formData, body)
  let scheme = call_593255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593255.url(scheme.get, call_593255.host, call_593255.base,
                         call_593255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593255, url, valid)

proc call*(call_593256: Call_GetDescribeDomains_593242;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593257 = newJObject()
  if DomainNames != nil:
    query_593257.add "DomainNames", DomainNames
  add(query_593257, "Action", newJString(Action))
  add(query_593257, "Version", newJString(Version))
  result = call_593256.call(nil, query_593257, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_593242(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_593243, base: "/",
    url: url_GetDescribeDomains_593244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_593292 = ref object of OpenApiRestCall_592364
proc url_PostDescribeIndexFields_593294(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeIndexFields_593293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593295 = query.getOrDefault("Action")
  valid_593295 = validateParameter(valid_593295, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_593295 != nil:
    section.add "Action", valid_593295
  var valid_593296 = query.getOrDefault("Version")
  valid_593296 = validateParameter(valid_593296, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593296 != nil:
    section.add "Version", valid_593296
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
  var valid_593297 = header.getOrDefault("X-Amz-Signature")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Signature", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-Content-Sha256", valid_593298
  var valid_593299 = header.getOrDefault("X-Amz-Date")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "X-Amz-Date", valid_593299
  var valid_593300 = header.getOrDefault("X-Amz-Credential")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "X-Amz-Credential", valid_593300
  var valid_593301 = header.getOrDefault("X-Amz-Security-Token")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "X-Amz-Security-Token", valid_593301
  var valid_593302 = header.getOrDefault("X-Amz-Algorithm")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "X-Amz-Algorithm", valid_593302
  var valid_593303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "X-Amz-SignedHeaders", valid_593303
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_593304 = formData.getOrDefault("FieldNames")
  valid_593304 = validateParameter(valid_593304, JArray, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "FieldNames", valid_593304
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593305 = formData.getOrDefault("DomainName")
  valid_593305 = validateParameter(valid_593305, JString, required = true,
                                 default = nil)
  if valid_593305 != nil:
    section.add "DomainName", valid_593305
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593306: Call_PostDescribeIndexFields_593292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_593306.validator(path, query, header, formData, body)
  let scheme = call_593306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593306.url(scheme.get, call_593306.host, call_593306.base,
                         call_593306.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593306, url, valid)

proc call*(call_593307: Call_PostDescribeIndexFields_593292; DomainName: string;
          FieldNames: JsonNode = nil; Action: string = "DescribeIndexFields";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593308 = newJObject()
  var formData_593309 = newJObject()
  if FieldNames != nil:
    formData_593309.add "FieldNames", FieldNames
  add(formData_593309, "DomainName", newJString(DomainName))
  add(query_593308, "Action", newJString(Action))
  add(query_593308, "Version", newJString(Version))
  result = call_593307.call(nil, query_593308, nil, formData_593309, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_593292(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_593293, base: "/",
    url: url_PostDescribeIndexFields_593294, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_593275 = ref object of OpenApiRestCall_592364
proc url_GetDescribeIndexFields_593277(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeIndexFields_593276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593278 = query.getOrDefault("DomainName")
  valid_593278 = validateParameter(valid_593278, JString, required = true,
                                 default = nil)
  if valid_593278 != nil:
    section.add "DomainName", valid_593278
  var valid_593279 = query.getOrDefault("Action")
  valid_593279 = validateParameter(valid_593279, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_593279 != nil:
    section.add "Action", valid_593279
  var valid_593280 = query.getOrDefault("Version")
  valid_593280 = validateParameter(valid_593280, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593280 != nil:
    section.add "Version", valid_593280
  var valid_593281 = query.getOrDefault("FieldNames")
  valid_593281 = validateParameter(valid_593281, JArray, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "FieldNames", valid_593281
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
  var valid_593282 = header.getOrDefault("X-Amz-Signature")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-Signature", valid_593282
  var valid_593283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593283 = validateParameter(valid_593283, JString, required = false,
                                 default = nil)
  if valid_593283 != nil:
    section.add "X-Amz-Content-Sha256", valid_593283
  var valid_593284 = header.getOrDefault("X-Amz-Date")
  valid_593284 = validateParameter(valid_593284, JString, required = false,
                                 default = nil)
  if valid_593284 != nil:
    section.add "X-Amz-Date", valid_593284
  var valid_593285 = header.getOrDefault("X-Amz-Credential")
  valid_593285 = validateParameter(valid_593285, JString, required = false,
                                 default = nil)
  if valid_593285 != nil:
    section.add "X-Amz-Credential", valid_593285
  var valid_593286 = header.getOrDefault("X-Amz-Security-Token")
  valid_593286 = validateParameter(valid_593286, JString, required = false,
                                 default = nil)
  if valid_593286 != nil:
    section.add "X-Amz-Security-Token", valid_593286
  var valid_593287 = header.getOrDefault("X-Amz-Algorithm")
  valid_593287 = validateParameter(valid_593287, JString, required = false,
                                 default = nil)
  if valid_593287 != nil:
    section.add "X-Amz-Algorithm", valid_593287
  var valid_593288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593288 = validateParameter(valid_593288, JString, required = false,
                                 default = nil)
  if valid_593288 != nil:
    section.add "X-Amz-SignedHeaders", valid_593288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593289: Call_GetDescribeIndexFields_593275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_593289.validator(path, query, header, formData, body)
  let scheme = call_593289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593289.url(scheme.get, call_593289.host, call_593289.base,
                         call_593289.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593289, url, valid)

proc call*(call_593290: Call_GetDescribeIndexFields_593275; DomainName: string;
          Action: string = "DescribeIndexFields"; Version: string = "2011-02-01";
          FieldNames: JsonNode = nil): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  var query_593291 = newJObject()
  add(query_593291, "DomainName", newJString(DomainName))
  add(query_593291, "Action", newJString(Action))
  add(query_593291, "Version", newJString(Version))
  if FieldNames != nil:
    query_593291.add "FieldNames", FieldNames
  result = call_593290.call(nil, query_593291, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_593275(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_593276, base: "/",
    url: url_GetDescribeIndexFields_593277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_593327 = ref object of OpenApiRestCall_592364
proc url_PostDescribeRankExpressions_593329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeRankExpressions_593328(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593330 = query.getOrDefault("Action")
  valid_593330 = validateParameter(valid_593330, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_593330 != nil:
    section.add "Action", valid_593330
  var valid_593331 = query.getOrDefault("Version")
  valid_593331 = validateParameter(valid_593331, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593331 != nil:
    section.add "Version", valid_593331
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
  var valid_593332 = header.getOrDefault("X-Amz-Signature")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Signature", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Content-Sha256", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Date")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Date", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-Credential")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-Credential", valid_593335
  var valid_593336 = header.getOrDefault("X-Amz-Security-Token")
  valid_593336 = validateParameter(valid_593336, JString, required = false,
                                 default = nil)
  if valid_593336 != nil:
    section.add "X-Amz-Security-Token", valid_593336
  var valid_593337 = header.getOrDefault("X-Amz-Algorithm")
  valid_593337 = validateParameter(valid_593337, JString, required = false,
                                 default = nil)
  if valid_593337 != nil:
    section.add "X-Amz-Algorithm", valid_593337
  var valid_593338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593338 = validateParameter(valid_593338, JString, required = false,
                                 default = nil)
  if valid_593338 != nil:
    section.add "X-Amz-SignedHeaders", valid_593338
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_593339 = formData.getOrDefault("RankNames")
  valid_593339 = validateParameter(valid_593339, JArray, required = false,
                                 default = nil)
  if valid_593339 != nil:
    section.add "RankNames", valid_593339
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593340 = formData.getOrDefault("DomainName")
  valid_593340 = validateParameter(valid_593340, JString, required = true,
                                 default = nil)
  if valid_593340 != nil:
    section.add "DomainName", valid_593340
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593341: Call_PostDescribeRankExpressions_593327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_593341.validator(path, query, header, formData, body)
  let scheme = call_593341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593341.url(scheme.get, call_593341.host, call_593341.base,
                         call_593341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593341, url, valid)

proc call*(call_593342: Call_PostDescribeRankExpressions_593327;
          DomainName: string; RankNames: JsonNode = nil;
          Action: string = "DescribeRankExpressions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593343 = newJObject()
  var formData_593344 = newJObject()
  if RankNames != nil:
    formData_593344.add "RankNames", RankNames
  add(formData_593344, "DomainName", newJString(DomainName))
  add(query_593343, "Action", newJString(Action))
  add(query_593343, "Version", newJString(Version))
  result = call_593342.call(nil, query_593343, nil, formData_593344, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_593327(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_593328, base: "/",
    url: url_PostDescribeRankExpressions_593329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_593310 = ref object of OpenApiRestCall_592364
proc url_GetDescribeRankExpressions_593312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeRankExpressions_593311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593313 = query.getOrDefault("DomainName")
  valid_593313 = validateParameter(valid_593313, JString, required = true,
                                 default = nil)
  if valid_593313 != nil:
    section.add "DomainName", valid_593313
  var valid_593314 = query.getOrDefault("RankNames")
  valid_593314 = validateParameter(valid_593314, JArray, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "RankNames", valid_593314
  var valid_593315 = query.getOrDefault("Action")
  valid_593315 = validateParameter(valid_593315, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_593315 != nil:
    section.add "Action", valid_593315
  var valid_593316 = query.getOrDefault("Version")
  valid_593316 = validateParameter(valid_593316, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593316 != nil:
    section.add "Version", valid_593316
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
  var valid_593317 = header.getOrDefault("X-Amz-Signature")
  valid_593317 = validateParameter(valid_593317, JString, required = false,
                                 default = nil)
  if valid_593317 != nil:
    section.add "X-Amz-Signature", valid_593317
  var valid_593318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593318 = validateParameter(valid_593318, JString, required = false,
                                 default = nil)
  if valid_593318 != nil:
    section.add "X-Amz-Content-Sha256", valid_593318
  var valid_593319 = header.getOrDefault("X-Amz-Date")
  valid_593319 = validateParameter(valid_593319, JString, required = false,
                                 default = nil)
  if valid_593319 != nil:
    section.add "X-Amz-Date", valid_593319
  var valid_593320 = header.getOrDefault("X-Amz-Credential")
  valid_593320 = validateParameter(valid_593320, JString, required = false,
                                 default = nil)
  if valid_593320 != nil:
    section.add "X-Amz-Credential", valid_593320
  var valid_593321 = header.getOrDefault("X-Amz-Security-Token")
  valid_593321 = validateParameter(valid_593321, JString, required = false,
                                 default = nil)
  if valid_593321 != nil:
    section.add "X-Amz-Security-Token", valid_593321
  var valid_593322 = header.getOrDefault("X-Amz-Algorithm")
  valid_593322 = validateParameter(valid_593322, JString, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "X-Amz-Algorithm", valid_593322
  var valid_593323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593323 = validateParameter(valid_593323, JString, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "X-Amz-SignedHeaders", valid_593323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593324: Call_GetDescribeRankExpressions_593310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_593324.validator(path, query, header, formData, body)
  let scheme = call_593324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593324.url(scheme.get, call_593324.host, call_593324.base,
                         call_593324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593324, url, valid)

proc call*(call_593325: Call_GetDescribeRankExpressions_593310; DomainName: string;
          RankNames: JsonNode = nil; Action: string = "DescribeRankExpressions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593326 = newJObject()
  add(query_593326, "DomainName", newJString(DomainName))
  if RankNames != nil:
    query_593326.add "RankNames", RankNames
  add(query_593326, "Action", newJString(Action))
  add(query_593326, "Version", newJString(Version))
  result = call_593325.call(nil, query_593326, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_593310(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_593311, base: "/",
    url: url_GetDescribeRankExpressions_593312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_593361 = ref object of OpenApiRestCall_592364
proc url_PostDescribeServiceAccessPolicies_593363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_593362(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593364 = query.getOrDefault("Action")
  valid_593364 = validateParameter(valid_593364, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_593364 != nil:
    section.add "Action", valid_593364
  var valid_593365 = query.getOrDefault("Version")
  valid_593365 = validateParameter(valid_593365, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593365 != nil:
    section.add "Version", valid_593365
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
  var valid_593366 = header.getOrDefault("X-Amz-Signature")
  valid_593366 = validateParameter(valid_593366, JString, required = false,
                                 default = nil)
  if valid_593366 != nil:
    section.add "X-Amz-Signature", valid_593366
  var valid_593367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Content-Sha256", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Date")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Date", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Credential")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Credential", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Security-Token")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Security-Token", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Algorithm")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Algorithm", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-SignedHeaders", valid_593372
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593373 = formData.getOrDefault("DomainName")
  valid_593373 = validateParameter(valid_593373, JString, required = true,
                                 default = nil)
  if valid_593373 != nil:
    section.add "DomainName", valid_593373
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593374: Call_PostDescribeServiceAccessPolicies_593361;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_593374.validator(path, query, header, formData, body)
  let scheme = call_593374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593374.url(scheme.get, call_593374.host, call_593374.base,
                         call_593374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593374, url, valid)

proc call*(call_593375: Call_PostDescribeServiceAccessPolicies_593361;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593376 = newJObject()
  var formData_593377 = newJObject()
  add(formData_593377, "DomainName", newJString(DomainName))
  add(query_593376, "Action", newJString(Action))
  add(query_593376, "Version", newJString(Version))
  result = call_593375.call(nil, query_593376, nil, formData_593377, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_593361(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_593362, base: "/",
    url: url_PostDescribeServiceAccessPolicies_593363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_593345 = ref object of OpenApiRestCall_592364
proc url_GetDescribeServiceAccessPolicies_593347(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_593346(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593348 = query.getOrDefault("DomainName")
  valid_593348 = validateParameter(valid_593348, JString, required = true,
                                 default = nil)
  if valid_593348 != nil:
    section.add "DomainName", valid_593348
  var valid_593349 = query.getOrDefault("Action")
  valid_593349 = validateParameter(valid_593349, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_593349 != nil:
    section.add "Action", valid_593349
  var valid_593350 = query.getOrDefault("Version")
  valid_593350 = validateParameter(valid_593350, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593350 != nil:
    section.add "Version", valid_593350
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
  var valid_593351 = header.getOrDefault("X-Amz-Signature")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "X-Amz-Signature", valid_593351
  var valid_593352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "X-Amz-Content-Sha256", valid_593352
  var valid_593353 = header.getOrDefault("X-Amz-Date")
  valid_593353 = validateParameter(valid_593353, JString, required = false,
                                 default = nil)
  if valid_593353 != nil:
    section.add "X-Amz-Date", valid_593353
  var valid_593354 = header.getOrDefault("X-Amz-Credential")
  valid_593354 = validateParameter(valid_593354, JString, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "X-Amz-Credential", valid_593354
  var valid_593355 = header.getOrDefault("X-Amz-Security-Token")
  valid_593355 = validateParameter(valid_593355, JString, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "X-Amz-Security-Token", valid_593355
  var valid_593356 = header.getOrDefault("X-Amz-Algorithm")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "X-Amz-Algorithm", valid_593356
  var valid_593357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593357 = validateParameter(valid_593357, JString, required = false,
                                 default = nil)
  if valid_593357 != nil:
    section.add "X-Amz-SignedHeaders", valid_593357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593358: Call_GetDescribeServiceAccessPolicies_593345;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_593358.validator(path, query, header, formData, body)
  let scheme = call_593358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593358.url(scheme.get, call_593358.host, call_593358.base,
                         call_593358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593358, url, valid)

proc call*(call_593359: Call_GetDescribeServiceAccessPolicies_593345;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593360 = newJObject()
  add(query_593360, "DomainName", newJString(DomainName))
  add(query_593360, "Action", newJString(Action))
  add(query_593360, "Version", newJString(Version))
  result = call_593359.call(nil, query_593360, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_593345(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_593346, base: "/",
    url: url_GetDescribeServiceAccessPolicies_593347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_593394 = ref object of OpenApiRestCall_592364
proc url_PostDescribeStemmingOptions_593396(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeStemmingOptions_593395(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593397 = query.getOrDefault("Action")
  valid_593397 = validateParameter(valid_593397, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_593397 != nil:
    section.add "Action", valid_593397
  var valid_593398 = query.getOrDefault("Version")
  valid_593398 = validateParameter(valid_593398, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593398 != nil:
    section.add "Version", valid_593398
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
  var valid_593399 = header.getOrDefault("X-Amz-Signature")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Signature", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Content-Sha256", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Date")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Date", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-Credential")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Credential", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-Security-Token")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Security-Token", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Algorithm")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Algorithm", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-SignedHeaders", valid_593405
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593406 = formData.getOrDefault("DomainName")
  valid_593406 = validateParameter(valid_593406, JString, required = true,
                                 default = nil)
  if valid_593406 != nil:
    section.add "DomainName", valid_593406
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593407: Call_PostDescribeStemmingOptions_593394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_593407.validator(path, query, header, formData, body)
  let scheme = call_593407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593407.url(scheme.get, call_593407.host, call_593407.base,
                         call_593407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593407, url, valid)

proc call*(call_593408: Call_PostDescribeStemmingOptions_593394;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593409 = newJObject()
  var formData_593410 = newJObject()
  add(formData_593410, "DomainName", newJString(DomainName))
  add(query_593409, "Action", newJString(Action))
  add(query_593409, "Version", newJString(Version))
  result = call_593408.call(nil, query_593409, nil, formData_593410, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_593394(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_593395, base: "/",
    url: url_PostDescribeStemmingOptions_593396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_593378 = ref object of OpenApiRestCall_592364
proc url_GetDescribeStemmingOptions_593380(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeStemmingOptions_593379(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593381 = query.getOrDefault("DomainName")
  valid_593381 = validateParameter(valid_593381, JString, required = true,
                                 default = nil)
  if valid_593381 != nil:
    section.add "DomainName", valid_593381
  var valid_593382 = query.getOrDefault("Action")
  valid_593382 = validateParameter(valid_593382, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_593382 != nil:
    section.add "Action", valid_593382
  var valid_593383 = query.getOrDefault("Version")
  valid_593383 = validateParameter(valid_593383, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593383 != nil:
    section.add "Version", valid_593383
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
  var valid_593384 = header.getOrDefault("X-Amz-Signature")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Signature", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Content-Sha256", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Date")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Date", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Credential")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Credential", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Security-Token")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Security-Token", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Algorithm")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Algorithm", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-SignedHeaders", valid_593390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593391: Call_GetDescribeStemmingOptions_593378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_593391.validator(path, query, header, formData, body)
  let scheme = call_593391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593391.url(scheme.get, call_593391.host, call_593391.base,
                         call_593391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593391, url, valid)

proc call*(call_593392: Call_GetDescribeStemmingOptions_593378; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593393 = newJObject()
  add(query_593393, "DomainName", newJString(DomainName))
  add(query_593393, "Action", newJString(Action))
  add(query_593393, "Version", newJString(Version))
  result = call_593392.call(nil, query_593393, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_593378(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_593379, base: "/",
    url: url_GetDescribeStemmingOptions_593380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_593427 = ref object of OpenApiRestCall_592364
proc url_PostDescribeStopwordOptions_593429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeStopwordOptions_593428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593430 = query.getOrDefault("Action")
  valid_593430 = validateParameter(valid_593430, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_593430 != nil:
    section.add "Action", valid_593430
  var valid_593431 = query.getOrDefault("Version")
  valid_593431 = validateParameter(valid_593431, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593431 != nil:
    section.add "Version", valid_593431
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
  var valid_593432 = header.getOrDefault("X-Amz-Signature")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Signature", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Content-Sha256", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Date")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Date", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Credential")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Credential", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-Security-Token")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Security-Token", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Algorithm")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Algorithm", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-SignedHeaders", valid_593438
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593439 = formData.getOrDefault("DomainName")
  valid_593439 = validateParameter(valid_593439, JString, required = true,
                                 default = nil)
  if valid_593439 != nil:
    section.add "DomainName", valid_593439
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593440: Call_PostDescribeStopwordOptions_593427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_593440.validator(path, query, header, formData, body)
  let scheme = call_593440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593440.url(scheme.get, call_593440.host, call_593440.base,
                         call_593440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593440, url, valid)

proc call*(call_593441: Call_PostDescribeStopwordOptions_593427;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593442 = newJObject()
  var formData_593443 = newJObject()
  add(formData_593443, "DomainName", newJString(DomainName))
  add(query_593442, "Action", newJString(Action))
  add(query_593442, "Version", newJString(Version))
  result = call_593441.call(nil, query_593442, nil, formData_593443, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_593427(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_593428, base: "/",
    url: url_PostDescribeStopwordOptions_593429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_593411 = ref object of OpenApiRestCall_592364
proc url_GetDescribeStopwordOptions_593413(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeStopwordOptions_593412(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593414 = query.getOrDefault("DomainName")
  valid_593414 = validateParameter(valid_593414, JString, required = true,
                                 default = nil)
  if valid_593414 != nil:
    section.add "DomainName", valid_593414
  var valid_593415 = query.getOrDefault("Action")
  valid_593415 = validateParameter(valid_593415, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_593415 != nil:
    section.add "Action", valid_593415
  var valid_593416 = query.getOrDefault("Version")
  valid_593416 = validateParameter(valid_593416, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593416 != nil:
    section.add "Version", valid_593416
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
  var valid_593417 = header.getOrDefault("X-Amz-Signature")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Signature", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Content-Sha256", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Date")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Date", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-Credential")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-Credential", valid_593420
  var valid_593421 = header.getOrDefault("X-Amz-Security-Token")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-Security-Token", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-Algorithm")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-Algorithm", valid_593422
  var valid_593423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593423 = validateParameter(valid_593423, JString, required = false,
                                 default = nil)
  if valid_593423 != nil:
    section.add "X-Amz-SignedHeaders", valid_593423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593424: Call_GetDescribeStopwordOptions_593411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_593424.validator(path, query, header, formData, body)
  let scheme = call_593424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593424.url(scheme.get, call_593424.host, call_593424.base,
                         call_593424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593424, url, valid)

proc call*(call_593425: Call_GetDescribeStopwordOptions_593411; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593426 = newJObject()
  add(query_593426, "DomainName", newJString(DomainName))
  add(query_593426, "Action", newJString(Action))
  add(query_593426, "Version", newJString(Version))
  result = call_593425.call(nil, query_593426, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_593411(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_593412, base: "/",
    url: url_GetDescribeStopwordOptions_593413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_593460 = ref object of OpenApiRestCall_592364
proc url_PostDescribeSynonymOptions_593462(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeSynonymOptions_593461(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593463 = query.getOrDefault("Action")
  valid_593463 = validateParameter(valid_593463, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_593463 != nil:
    section.add "Action", valid_593463
  var valid_593464 = query.getOrDefault("Version")
  valid_593464 = validateParameter(valid_593464, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593464 != nil:
    section.add "Version", valid_593464
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
  var valid_593465 = header.getOrDefault("X-Amz-Signature")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Signature", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-Content-Sha256", valid_593466
  var valid_593467 = header.getOrDefault("X-Amz-Date")
  valid_593467 = validateParameter(valid_593467, JString, required = false,
                                 default = nil)
  if valid_593467 != nil:
    section.add "X-Amz-Date", valid_593467
  var valid_593468 = header.getOrDefault("X-Amz-Credential")
  valid_593468 = validateParameter(valid_593468, JString, required = false,
                                 default = nil)
  if valid_593468 != nil:
    section.add "X-Amz-Credential", valid_593468
  var valid_593469 = header.getOrDefault("X-Amz-Security-Token")
  valid_593469 = validateParameter(valid_593469, JString, required = false,
                                 default = nil)
  if valid_593469 != nil:
    section.add "X-Amz-Security-Token", valid_593469
  var valid_593470 = header.getOrDefault("X-Amz-Algorithm")
  valid_593470 = validateParameter(valid_593470, JString, required = false,
                                 default = nil)
  if valid_593470 != nil:
    section.add "X-Amz-Algorithm", valid_593470
  var valid_593471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-SignedHeaders", valid_593471
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593472 = formData.getOrDefault("DomainName")
  valid_593472 = validateParameter(valid_593472, JString, required = true,
                                 default = nil)
  if valid_593472 != nil:
    section.add "DomainName", valid_593472
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593473: Call_PostDescribeSynonymOptions_593460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_593473.validator(path, query, header, formData, body)
  let scheme = call_593473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593473.url(scheme.get, call_593473.host, call_593473.base,
                         call_593473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593473, url, valid)

proc call*(call_593474: Call_PostDescribeSynonymOptions_593460; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593475 = newJObject()
  var formData_593476 = newJObject()
  add(formData_593476, "DomainName", newJString(DomainName))
  add(query_593475, "Action", newJString(Action))
  add(query_593475, "Version", newJString(Version))
  result = call_593474.call(nil, query_593475, nil, formData_593476, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_593460(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_593461, base: "/",
    url: url_PostDescribeSynonymOptions_593462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_593444 = ref object of OpenApiRestCall_592364
proc url_GetDescribeSynonymOptions_593446(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeSynonymOptions_593445(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593447 = query.getOrDefault("DomainName")
  valid_593447 = validateParameter(valid_593447, JString, required = true,
                                 default = nil)
  if valid_593447 != nil:
    section.add "DomainName", valid_593447
  var valid_593448 = query.getOrDefault("Action")
  valid_593448 = validateParameter(valid_593448, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_593448 != nil:
    section.add "Action", valid_593448
  var valid_593449 = query.getOrDefault("Version")
  valid_593449 = validateParameter(valid_593449, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593449 != nil:
    section.add "Version", valid_593449
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
  var valid_593450 = header.getOrDefault("X-Amz-Signature")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Signature", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Content-Sha256", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Date")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Date", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Credential")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Credential", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Security-Token")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Security-Token", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Algorithm")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Algorithm", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-SignedHeaders", valid_593456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593457: Call_GetDescribeSynonymOptions_593444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_593457.validator(path, query, header, formData, body)
  let scheme = call_593457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593457.url(scheme.get, call_593457.host, call_593457.base,
                         call_593457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593457, url, valid)

proc call*(call_593458: Call_GetDescribeSynonymOptions_593444; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593459 = newJObject()
  add(query_593459, "DomainName", newJString(DomainName))
  add(query_593459, "Action", newJString(Action))
  add(query_593459, "Version", newJString(Version))
  result = call_593458.call(nil, query_593459, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_593444(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_593445, base: "/",
    url: url_GetDescribeSynonymOptions_593446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_593493 = ref object of OpenApiRestCall_592364
proc url_PostIndexDocuments_593495(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostIndexDocuments_593494(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593496 = query.getOrDefault("Action")
  valid_593496 = validateParameter(valid_593496, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_593496 != nil:
    section.add "Action", valid_593496
  var valid_593497 = query.getOrDefault("Version")
  valid_593497 = validateParameter(valid_593497, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593497 != nil:
    section.add "Version", valid_593497
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
  var valid_593498 = header.getOrDefault("X-Amz-Signature")
  valid_593498 = validateParameter(valid_593498, JString, required = false,
                                 default = nil)
  if valid_593498 != nil:
    section.add "X-Amz-Signature", valid_593498
  var valid_593499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593499 = validateParameter(valid_593499, JString, required = false,
                                 default = nil)
  if valid_593499 != nil:
    section.add "X-Amz-Content-Sha256", valid_593499
  var valid_593500 = header.getOrDefault("X-Amz-Date")
  valid_593500 = validateParameter(valid_593500, JString, required = false,
                                 default = nil)
  if valid_593500 != nil:
    section.add "X-Amz-Date", valid_593500
  var valid_593501 = header.getOrDefault("X-Amz-Credential")
  valid_593501 = validateParameter(valid_593501, JString, required = false,
                                 default = nil)
  if valid_593501 != nil:
    section.add "X-Amz-Credential", valid_593501
  var valid_593502 = header.getOrDefault("X-Amz-Security-Token")
  valid_593502 = validateParameter(valid_593502, JString, required = false,
                                 default = nil)
  if valid_593502 != nil:
    section.add "X-Amz-Security-Token", valid_593502
  var valid_593503 = header.getOrDefault("X-Amz-Algorithm")
  valid_593503 = validateParameter(valid_593503, JString, required = false,
                                 default = nil)
  if valid_593503 != nil:
    section.add "X-Amz-Algorithm", valid_593503
  var valid_593504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593504 = validateParameter(valid_593504, JString, required = false,
                                 default = nil)
  if valid_593504 != nil:
    section.add "X-Amz-SignedHeaders", valid_593504
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593505 = formData.getOrDefault("DomainName")
  valid_593505 = validateParameter(valid_593505, JString, required = true,
                                 default = nil)
  if valid_593505 != nil:
    section.add "DomainName", valid_593505
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593506: Call_PostIndexDocuments_593493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_593506.validator(path, query, header, formData, body)
  let scheme = call_593506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593506.url(scheme.get, call_593506.host, call_593506.base,
                         call_593506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593506, url, valid)

proc call*(call_593507: Call_PostIndexDocuments_593493; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593508 = newJObject()
  var formData_593509 = newJObject()
  add(formData_593509, "DomainName", newJString(DomainName))
  add(query_593508, "Action", newJString(Action))
  add(query_593508, "Version", newJString(Version))
  result = call_593507.call(nil, query_593508, nil, formData_593509, nil)

var postIndexDocuments* = Call_PostIndexDocuments_593493(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_593494, base: "/",
    url: url_PostIndexDocuments_593495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_593477 = ref object of OpenApiRestCall_592364
proc url_GetIndexDocuments_593479(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIndexDocuments_593478(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593480 = query.getOrDefault("DomainName")
  valid_593480 = validateParameter(valid_593480, JString, required = true,
                                 default = nil)
  if valid_593480 != nil:
    section.add "DomainName", valid_593480
  var valid_593481 = query.getOrDefault("Action")
  valid_593481 = validateParameter(valid_593481, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_593481 != nil:
    section.add "Action", valid_593481
  var valid_593482 = query.getOrDefault("Version")
  valid_593482 = validateParameter(valid_593482, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593482 != nil:
    section.add "Version", valid_593482
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
  var valid_593483 = header.getOrDefault("X-Amz-Signature")
  valid_593483 = validateParameter(valid_593483, JString, required = false,
                                 default = nil)
  if valid_593483 != nil:
    section.add "X-Amz-Signature", valid_593483
  var valid_593484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593484 = validateParameter(valid_593484, JString, required = false,
                                 default = nil)
  if valid_593484 != nil:
    section.add "X-Amz-Content-Sha256", valid_593484
  var valid_593485 = header.getOrDefault("X-Amz-Date")
  valid_593485 = validateParameter(valid_593485, JString, required = false,
                                 default = nil)
  if valid_593485 != nil:
    section.add "X-Amz-Date", valid_593485
  var valid_593486 = header.getOrDefault("X-Amz-Credential")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Credential", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Security-Token")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Security-Token", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Algorithm")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Algorithm", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-SignedHeaders", valid_593489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593490: Call_GetIndexDocuments_593477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_593490.validator(path, query, header, formData, body)
  let scheme = call_593490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593490.url(scheme.get, call_593490.host, call_593490.base,
                         call_593490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593490, url, valid)

proc call*(call_593491: Call_GetIndexDocuments_593477; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593492 = newJObject()
  add(query_593492, "DomainName", newJString(DomainName))
  add(query_593492, "Action", newJString(Action))
  add(query_593492, "Version", newJString(Version))
  result = call_593491.call(nil, query_593492, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_593477(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_593478,
    base: "/", url: url_GetIndexDocuments_593479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_593527 = ref object of OpenApiRestCall_592364
proc url_PostUpdateAvailabilityOptions_593529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateAvailabilityOptions_593528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593530 = query.getOrDefault("Action")
  valid_593530 = validateParameter(valid_593530, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_593530 != nil:
    section.add "Action", valid_593530
  var valid_593531 = query.getOrDefault("Version")
  valid_593531 = validateParameter(valid_593531, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593531 != nil:
    section.add "Version", valid_593531
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
  var valid_593532 = header.getOrDefault("X-Amz-Signature")
  valid_593532 = validateParameter(valid_593532, JString, required = false,
                                 default = nil)
  if valid_593532 != nil:
    section.add "X-Amz-Signature", valid_593532
  var valid_593533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593533 = validateParameter(valid_593533, JString, required = false,
                                 default = nil)
  if valid_593533 != nil:
    section.add "X-Amz-Content-Sha256", valid_593533
  var valid_593534 = header.getOrDefault("X-Amz-Date")
  valid_593534 = validateParameter(valid_593534, JString, required = false,
                                 default = nil)
  if valid_593534 != nil:
    section.add "X-Amz-Date", valid_593534
  var valid_593535 = header.getOrDefault("X-Amz-Credential")
  valid_593535 = validateParameter(valid_593535, JString, required = false,
                                 default = nil)
  if valid_593535 != nil:
    section.add "X-Amz-Credential", valid_593535
  var valid_593536 = header.getOrDefault("X-Amz-Security-Token")
  valid_593536 = validateParameter(valid_593536, JString, required = false,
                                 default = nil)
  if valid_593536 != nil:
    section.add "X-Amz-Security-Token", valid_593536
  var valid_593537 = header.getOrDefault("X-Amz-Algorithm")
  valid_593537 = validateParameter(valid_593537, JString, required = false,
                                 default = nil)
  if valid_593537 != nil:
    section.add "X-Amz-Algorithm", valid_593537
  var valid_593538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "X-Amz-SignedHeaders", valid_593538
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_593539 = formData.getOrDefault("MultiAZ")
  valid_593539 = validateParameter(valid_593539, JBool, required = true, default = nil)
  if valid_593539 != nil:
    section.add "MultiAZ", valid_593539
  var valid_593540 = formData.getOrDefault("DomainName")
  valid_593540 = validateParameter(valid_593540, JString, required = true,
                                 default = nil)
  if valid_593540 != nil:
    section.add "DomainName", valid_593540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593541: Call_PostUpdateAvailabilityOptions_593527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593541.validator(path, query, header, formData, body)
  let scheme = call_593541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593541.url(scheme.get, call_593541.host, call_593541.base,
                         call_593541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593541, url, valid)

proc call*(call_593542: Call_PostUpdateAvailabilityOptions_593527; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593543 = newJObject()
  var formData_593544 = newJObject()
  add(formData_593544, "MultiAZ", newJBool(MultiAZ))
  add(formData_593544, "DomainName", newJString(DomainName))
  add(query_593543, "Action", newJString(Action))
  add(query_593543, "Version", newJString(Version))
  result = call_593542.call(nil, query_593543, nil, formData_593544, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_593527(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_593528, base: "/",
    url: url_PostUpdateAvailabilityOptions_593529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_593510 = ref object of OpenApiRestCall_592364
proc url_GetUpdateAvailabilityOptions_593512(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateAvailabilityOptions_593511(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593513 = query.getOrDefault("DomainName")
  valid_593513 = validateParameter(valid_593513, JString, required = true,
                                 default = nil)
  if valid_593513 != nil:
    section.add "DomainName", valid_593513
  var valid_593514 = query.getOrDefault("Action")
  valid_593514 = validateParameter(valid_593514, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_593514 != nil:
    section.add "Action", valid_593514
  var valid_593515 = query.getOrDefault("MultiAZ")
  valid_593515 = validateParameter(valid_593515, JBool, required = true, default = nil)
  if valid_593515 != nil:
    section.add "MultiAZ", valid_593515
  var valid_593516 = query.getOrDefault("Version")
  valid_593516 = validateParameter(valid_593516, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593516 != nil:
    section.add "Version", valid_593516
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
  var valid_593517 = header.getOrDefault("X-Amz-Signature")
  valid_593517 = validateParameter(valid_593517, JString, required = false,
                                 default = nil)
  if valid_593517 != nil:
    section.add "X-Amz-Signature", valid_593517
  var valid_593518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593518 = validateParameter(valid_593518, JString, required = false,
                                 default = nil)
  if valid_593518 != nil:
    section.add "X-Amz-Content-Sha256", valid_593518
  var valid_593519 = header.getOrDefault("X-Amz-Date")
  valid_593519 = validateParameter(valid_593519, JString, required = false,
                                 default = nil)
  if valid_593519 != nil:
    section.add "X-Amz-Date", valid_593519
  var valid_593520 = header.getOrDefault("X-Amz-Credential")
  valid_593520 = validateParameter(valid_593520, JString, required = false,
                                 default = nil)
  if valid_593520 != nil:
    section.add "X-Amz-Credential", valid_593520
  var valid_593521 = header.getOrDefault("X-Amz-Security-Token")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Security-Token", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Algorithm")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Algorithm", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-SignedHeaders", valid_593523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593524: Call_GetUpdateAvailabilityOptions_593510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_593524.validator(path, query, header, formData, body)
  let scheme = call_593524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593524.url(scheme.get, call_593524.host, call_593524.base,
                         call_593524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593524, url, valid)

proc call*(call_593525: Call_GetUpdateAvailabilityOptions_593510;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: string (required)
  var query_593526 = newJObject()
  add(query_593526, "DomainName", newJString(DomainName))
  add(query_593526, "Action", newJString(Action))
  add(query_593526, "MultiAZ", newJBool(MultiAZ))
  add(query_593526, "Version", newJString(Version))
  result = call_593525.call(nil, query_593526, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_593510(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_593511, base: "/",
    url: url_GetUpdateAvailabilityOptions_593512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_593562 = ref object of OpenApiRestCall_592364
proc url_PostUpdateDefaultSearchField_593564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateDefaultSearchField_593563(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593565 = query.getOrDefault("Action")
  valid_593565 = validateParameter(valid_593565, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_593565 != nil:
    section.add "Action", valid_593565
  var valid_593566 = query.getOrDefault("Version")
  valid_593566 = validateParameter(valid_593566, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593566 != nil:
    section.add "Version", valid_593566
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
  var valid_593567 = header.getOrDefault("X-Amz-Signature")
  valid_593567 = validateParameter(valid_593567, JString, required = false,
                                 default = nil)
  if valid_593567 != nil:
    section.add "X-Amz-Signature", valid_593567
  var valid_593568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593568 = validateParameter(valid_593568, JString, required = false,
                                 default = nil)
  if valid_593568 != nil:
    section.add "X-Amz-Content-Sha256", valid_593568
  var valid_593569 = header.getOrDefault("X-Amz-Date")
  valid_593569 = validateParameter(valid_593569, JString, required = false,
                                 default = nil)
  if valid_593569 != nil:
    section.add "X-Amz-Date", valid_593569
  var valid_593570 = header.getOrDefault("X-Amz-Credential")
  valid_593570 = validateParameter(valid_593570, JString, required = false,
                                 default = nil)
  if valid_593570 != nil:
    section.add "X-Amz-Credential", valid_593570
  var valid_593571 = header.getOrDefault("X-Amz-Security-Token")
  valid_593571 = validateParameter(valid_593571, JString, required = false,
                                 default = nil)
  if valid_593571 != nil:
    section.add "X-Amz-Security-Token", valid_593571
  var valid_593572 = header.getOrDefault("X-Amz-Algorithm")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-Algorithm", valid_593572
  var valid_593573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "X-Amz-SignedHeaders", valid_593573
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593574 = formData.getOrDefault("DomainName")
  valid_593574 = validateParameter(valid_593574, JString, required = true,
                                 default = nil)
  if valid_593574 != nil:
    section.add "DomainName", valid_593574
  var valid_593575 = formData.getOrDefault("DefaultSearchField")
  valid_593575 = validateParameter(valid_593575, JString, required = true,
                                 default = nil)
  if valid_593575 != nil:
    section.add "DefaultSearchField", valid_593575
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593576: Call_PostUpdateDefaultSearchField_593562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_593576.validator(path, query, header, formData, body)
  let scheme = call_593576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593576.url(scheme.get, call_593576.host, call_593576.base,
                         call_593576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593576, url, valid)

proc call*(call_593577: Call_PostUpdateDefaultSearchField_593562;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: string (required)
  var query_593578 = newJObject()
  var formData_593579 = newJObject()
  add(formData_593579, "DomainName", newJString(DomainName))
  add(query_593578, "Action", newJString(Action))
  add(formData_593579, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_593578, "Version", newJString(Version))
  result = call_593577.call(nil, query_593578, nil, formData_593579, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_593562(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_593563, base: "/",
    url: url_PostUpdateDefaultSearchField_593564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_593545 = ref object of OpenApiRestCall_592364
proc url_GetUpdateDefaultSearchField_593547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateDefaultSearchField_593546(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593548 = query.getOrDefault("DomainName")
  valid_593548 = validateParameter(valid_593548, JString, required = true,
                                 default = nil)
  if valid_593548 != nil:
    section.add "DomainName", valid_593548
  var valid_593549 = query.getOrDefault("DefaultSearchField")
  valid_593549 = validateParameter(valid_593549, JString, required = true,
                                 default = nil)
  if valid_593549 != nil:
    section.add "DefaultSearchField", valid_593549
  var valid_593550 = query.getOrDefault("Action")
  valid_593550 = validateParameter(valid_593550, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_593550 != nil:
    section.add "Action", valid_593550
  var valid_593551 = query.getOrDefault("Version")
  valid_593551 = validateParameter(valid_593551, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593551 != nil:
    section.add "Version", valid_593551
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
  var valid_593552 = header.getOrDefault("X-Amz-Signature")
  valid_593552 = validateParameter(valid_593552, JString, required = false,
                                 default = nil)
  if valid_593552 != nil:
    section.add "X-Amz-Signature", valid_593552
  var valid_593553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593553 = validateParameter(valid_593553, JString, required = false,
                                 default = nil)
  if valid_593553 != nil:
    section.add "X-Amz-Content-Sha256", valid_593553
  var valid_593554 = header.getOrDefault("X-Amz-Date")
  valid_593554 = validateParameter(valid_593554, JString, required = false,
                                 default = nil)
  if valid_593554 != nil:
    section.add "X-Amz-Date", valid_593554
  var valid_593555 = header.getOrDefault("X-Amz-Credential")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "X-Amz-Credential", valid_593555
  var valid_593556 = header.getOrDefault("X-Amz-Security-Token")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Security-Token", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-Algorithm")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Algorithm", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-SignedHeaders", valid_593558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593559: Call_GetUpdateDefaultSearchField_593545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_593559.validator(path, query, header, formData, body)
  let scheme = call_593559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593559.url(scheme.get, call_593559.host, call_593559.base,
                         call_593559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593559, url, valid)

proc call*(call_593560: Call_GetUpdateDefaultSearchField_593545;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593561 = newJObject()
  add(query_593561, "DomainName", newJString(DomainName))
  add(query_593561, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_593561, "Action", newJString(Action))
  add(query_593561, "Version", newJString(Version))
  result = call_593560.call(nil, query_593561, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_593545(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_593546, base: "/",
    url: url_GetUpdateDefaultSearchField_593547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_593597 = ref object of OpenApiRestCall_592364
proc url_PostUpdateServiceAccessPolicies_593599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_593598(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593600 = query.getOrDefault("Action")
  valid_593600 = validateParameter(valid_593600, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_593600 != nil:
    section.add "Action", valid_593600
  var valid_593601 = query.getOrDefault("Version")
  valid_593601 = validateParameter(valid_593601, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593601 != nil:
    section.add "Version", valid_593601
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
  var valid_593602 = header.getOrDefault("X-Amz-Signature")
  valid_593602 = validateParameter(valid_593602, JString, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "X-Amz-Signature", valid_593602
  var valid_593603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593603 = validateParameter(valid_593603, JString, required = false,
                                 default = nil)
  if valid_593603 != nil:
    section.add "X-Amz-Content-Sha256", valid_593603
  var valid_593604 = header.getOrDefault("X-Amz-Date")
  valid_593604 = validateParameter(valid_593604, JString, required = false,
                                 default = nil)
  if valid_593604 != nil:
    section.add "X-Amz-Date", valid_593604
  var valid_593605 = header.getOrDefault("X-Amz-Credential")
  valid_593605 = validateParameter(valid_593605, JString, required = false,
                                 default = nil)
  if valid_593605 != nil:
    section.add "X-Amz-Credential", valid_593605
  var valid_593606 = header.getOrDefault("X-Amz-Security-Token")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Security-Token", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Algorithm")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Algorithm", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-SignedHeaders", valid_593608
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessPolicies` field"
  var valid_593609 = formData.getOrDefault("AccessPolicies")
  valid_593609 = validateParameter(valid_593609, JString, required = true,
                                 default = nil)
  if valid_593609 != nil:
    section.add "AccessPolicies", valid_593609
  var valid_593610 = formData.getOrDefault("DomainName")
  valid_593610 = validateParameter(valid_593610, JString, required = true,
                                 default = nil)
  if valid_593610 != nil:
    section.add "DomainName", valid_593610
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593611: Call_PostUpdateServiceAccessPolicies_593597;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_593611.validator(path, query, header, formData, body)
  let scheme = call_593611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593611.url(scheme.get, call_593611.host, call_593611.base,
                         call_593611.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593611, url, valid)

proc call*(call_593612: Call_PostUpdateServiceAccessPolicies_593597;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593613 = newJObject()
  var formData_593614 = newJObject()
  add(formData_593614, "AccessPolicies", newJString(AccessPolicies))
  add(formData_593614, "DomainName", newJString(DomainName))
  add(query_593613, "Action", newJString(Action))
  add(query_593613, "Version", newJString(Version))
  result = call_593612.call(nil, query_593613, nil, formData_593614, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_593597(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_593598, base: "/",
    url: url_PostUpdateServiceAccessPolicies_593599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_593580 = ref object of OpenApiRestCall_592364
proc url_GetUpdateServiceAccessPolicies_593582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_593581(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_593583 = query.getOrDefault("DomainName")
  valid_593583 = validateParameter(valid_593583, JString, required = true,
                                 default = nil)
  if valid_593583 != nil:
    section.add "DomainName", valid_593583
  var valid_593584 = query.getOrDefault("Action")
  valid_593584 = validateParameter(valid_593584, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_593584 != nil:
    section.add "Action", valid_593584
  var valid_593585 = query.getOrDefault("Version")
  valid_593585 = validateParameter(valid_593585, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593585 != nil:
    section.add "Version", valid_593585
  var valid_593586 = query.getOrDefault("AccessPolicies")
  valid_593586 = validateParameter(valid_593586, JString, required = true,
                                 default = nil)
  if valid_593586 != nil:
    section.add "AccessPolicies", valid_593586
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
  var valid_593587 = header.getOrDefault("X-Amz-Signature")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Signature", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Content-Sha256", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Date")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Date", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-Credential")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Credential", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Security-Token")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Security-Token", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Algorithm")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Algorithm", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-SignedHeaders", valid_593593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593594: Call_GetUpdateServiceAccessPolicies_593580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_593594.validator(path, query, header, formData, body)
  let scheme = call_593594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593594.url(scheme.get, call_593594.host, call_593594.base,
                         call_593594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593594, url, valid)

proc call*(call_593595: Call_GetUpdateServiceAccessPolicies_593580;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  var query_593596 = newJObject()
  add(query_593596, "DomainName", newJString(DomainName))
  add(query_593596, "Action", newJString(Action))
  add(query_593596, "Version", newJString(Version))
  add(query_593596, "AccessPolicies", newJString(AccessPolicies))
  result = call_593595.call(nil, query_593596, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_593580(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_593581, base: "/",
    url: url_GetUpdateServiceAccessPolicies_593582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_593632 = ref object of OpenApiRestCall_592364
proc url_PostUpdateStemmingOptions_593634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateStemmingOptions_593633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593635 = query.getOrDefault("Action")
  valid_593635 = validateParameter(valid_593635, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_593635 != nil:
    section.add "Action", valid_593635
  var valid_593636 = query.getOrDefault("Version")
  valid_593636 = validateParameter(valid_593636, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593636 != nil:
    section.add "Version", valid_593636
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
  var valid_593637 = header.getOrDefault("X-Amz-Signature")
  valid_593637 = validateParameter(valid_593637, JString, required = false,
                                 default = nil)
  if valid_593637 != nil:
    section.add "X-Amz-Signature", valid_593637
  var valid_593638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593638 = validateParameter(valid_593638, JString, required = false,
                                 default = nil)
  if valid_593638 != nil:
    section.add "X-Amz-Content-Sha256", valid_593638
  var valid_593639 = header.getOrDefault("X-Amz-Date")
  valid_593639 = validateParameter(valid_593639, JString, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "X-Amz-Date", valid_593639
  var valid_593640 = header.getOrDefault("X-Amz-Credential")
  valid_593640 = validateParameter(valid_593640, JString, required = false,
                                 default = nil)
  if valid_593640 != nil:
    section.add "X-Amz-Credential", valid_593640
  var valid_593641 = header.getOrDefault("X-Amz-Security-Token")
  valid_593641 = validateParameter(valid_593641, JString, required = false,
                                 default = nil)
  if valid_593641 != nil:
    section.add "X-Amz-Security-Token", valid_593641
  var valid_593642 = header.getOrDefault("X-Amz-Algorithm")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Algorithm", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-SignedHeaders", valid_593643
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593644 = formData.getOrDefault("DomainName")
  valid_593644 = validateParameter(valid_593644, JString, required = true,
                                 default = nil)
  if valid_593644 != nil:
    section.add "DomainName", valid_593644
  var valid_593645 = formData.getOrDefault("Stems")
  valid_593645 = validateParameter(valid_593645, JString, required = true,
                                 default = nil)
  if valid_593645 != nil:
    section.add "Stems", valid_593645
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593646: Call_PostUpdateStemmingOptions_593632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_593646.validator(path, query, header, formData, body)
  let scheme = call_593646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593646.url(scheme.get, call_593646.host, call_593646.base,
                         call_593646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593646, url, valid)

proc call*(call_593647: Call_PostUpdateStemmingOptions_593632; DomainName: string;
          Stems: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   Version: string (required)
  var query_593648 = newJObject()
  var formData_593649 = newJObject()
  add(formData_593649, "DomainName", newJString(DomainName))
  add(query_593648, "Action", newJString(Action))
  add(formData_593649, "Stems", newJString(Stems))
  add(query_593648, "Version", newJString(Version))
  result = call_593647.call(nil, query_593648, nil, formData_593649, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_593632(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_593633, base: "/",
    url: url_PostUpdateStemmingOptions_593634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_593615 = ref object of OpenApiRestCall_592364
proc url_GetUpdateStemmingOptions_593617(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateStemmingOptions_593616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Stems` field"
  var valid_593618 = query.getOrDefault("Stems")
  valid_593618 = validateParameter(valid_593618, JString, required = true,
                                 default = nil)
  if valid_593618 != nil:
    section.add "Stems", valid_593618
  var valid_593619 = query.getOrDefault("DomainName")
  valid_593619 = validateParameter(valid_593619, JString, required = true,
                                 default = nil)
  if valid_593619 != nil:
    section.add "DomainName", valid_593619
  var valid_593620 = query.getOrDefault("Action")
  valid_593620 = validateParameter(valid_593620, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_593620 != nil:
    section.add "Action", valid_593620
  var valid_593621 = query.getOrDefault("Version")
  valid_593621 = validateParameter(valid_593621, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593621 != nil:
    section.add "Version", valid_593621
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
  var valid_593622 = header.getOrDefault("X-Amz-Signature")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Signature", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Content-Sha256", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Date")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Date", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Credential")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Credential", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Security-Token")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Security-Token", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-Algorithm")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-Algorithm", valid_593627
  var valid_593628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "X-Amz-SignedHeaders", valid_593628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593629: Call_GetUpdateStemmingOptions_593615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_593629.validator(path, query, header, formData, body)
  let scheme = call_593629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593629.url(scheme.get, call_593629.host, call_593629.base,
                         call_593629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593629, url, valid)

proc call*(call_593630: Call_GetUpdateStemmingOptions_593615; Stems: string;
          DomainName: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593631 = newJObject()
  add(query_593631, "Stems", newJString(Stems))
  add(query_593631, "DomainName", newJString(DomainName))
  add(query_593631, "Action", newJString(Action))
  add(query_593631, "Version", newJString(Version))
  result = call_593630.call(nil, query_593631, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_593615(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_593616, base: "/",
    url: url_GetUpdateStemmingOptions_593617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_593667 = ref object of OpenApiRestCall_592364
proc url_PostUpdateStopwordOptions_593669(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateStopwordOptions_593668(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593670 = query.getOrDefault("Action")
  valid_593670 = validateParameter(valid_593670, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_593670 != nil:
    section.add "Action", valid_593670
  var valid_593671 = query.getOrDefault("Version")
  valid_593671 = validateParameter(valid_593671, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593671 != nil:
    section.add "Version", valid_593671
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
  var valid_593672 = header.getOrDefault("X-Amz-Signature")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "X-Amz-Signature", valid_593672
  var valid_593673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593673 = validateParameter(valid_593673, JString, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "X-Amz-Content-Sha256", valid_593673
  var valid_593674 = header.getOrDefault("X-Amz-Date")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "X-Amz-Date", valid_593674
  var valid_593675 = header.getOrDefault("X-Amz-Credential")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "X-Amz-Credential", valid_593675
  var valid_593676 = header.getOrDefault("X-Amz-Security-Token")
  valid_593676 = validateParameter(valid_593676, JString, required = false,
                                 default = nil)
  if valid_593676 != nil:
    section.add "X-Amz-Security-Token", valid_593676
  var valid_593677 = header.getOrDefault("X-Amz-Algorithm")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "X-Amz-Algorithm", valid_593677
  var valid_593678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593678 = validateParameter(valid_593678, JString, required = false,
                                 default = nil)
  if valid_593678 != nil:
    section.add "X-Amz-SignedHeaders", valid_593678
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_593679 = formData.getOrDefault("Stopwords")
  valid_593679 = validateParameter(valid_593679, JString, required = true,
                                 default = nil)
  if valid_593679 != nil:
    section.add "Stopwords", valid_593679
  var valid_593680 = formData.getOrDefault("DomainName")
  valid_593680 = validateParameter(valid_593680, JString, required = true,
                                 default = nil)
  if valid_593680 != nil:
    section.add "DomainName", valid_593680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593681: Call_PostUpdateStopwordOptions_593667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_593681.validator(path, query, header, formData, body)
  let scheme = call_593681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593681.url(scheme.get, call_593681.host, call_593681.base,
                         call_593681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593681, url, valid)

proc call*(call_593682: Call_PostUpdateStopwordOptions_593667; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593683 = newJObject()
  var formData_593684 = newJObject()
  add(formData_593684, "Stopwords", newJString(Stopwords))
  add(formData_593684, "DomainName", newJString(DomainName))
  add(query_593683, "Action", newJString(Action))
  add(query_593683, "Version", newJString(Version))
  result = call_593682.call(nil, query_593683, nil, formData_593684, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_593667(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_593668, base: "/",
    url: url_PostUpdateStopwordOptions_593669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_593650 = ref object of OpenApiRestCall_592364
proc url_GetUpdateStopwordOptions_593652(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateStopwordOptions_593651(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Stopwords` field"
  var valid_593653 = query.getOrDefault("Stopwords")
  valid_593653 = validateParameter(valid_593653, JString, required = true,
                                 default = nil)
  if valid_593653 != nil:
    section.add "Stopwords", valid_593653
  var valid_593654 = query.getOrDefault("DomainName")
  valid_593654 = validateParameter(valid_593654, JString, required = true,
                                 default = nil)
  if valid_593654 != nil:
    section.add "DomainName", valid_593654
  var valid_593655 = query.getOrDefault("Action")
  valid_593655 = validateParameter(valid_593655, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_593655 != nil:
    section.add "Action", valid_593655
  var valid_593656 = query.getOrDefault("Version")
  valid_593656 = validateParameter(valid_593656, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593656 != nil:
    section.add "Version", valid_593656
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
  var valid_593657 = header.getOrDefault("X-Amz-Signature")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Signature", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Content-Sha256", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-Date")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Date", valid_593659
  var valid_593660 = header.getOrDefault("X-Amz-Credential")
  valid_593660 = validateParameter(valid_593660, JString, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "X-Amz-Credential", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Security-Token")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Security-Token", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Algorithm")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Algorithm", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-SignedHeaders", valid_593663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593664: Call_GetUpdateStopwordOptions_593650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_593664.validator(path, query, header, formData, body)
  let scheme = call_593664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593664.url(scheme.get, call_593664.host, call_593664.base,
                         call_593664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593664, url, valid)

proc call*(call_593665: Call_GetUpdateStopwordOptions_593650; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593666 = newJObject()
  add(query_593666, "Stopwords", newJString(Stopwords))
  add(query_593666, "DomainName", newJString(DomainName))
  add(query_593666, "Action", newJString(Action))
  add(query_593666, "Version", newJString(Version))
  result = call_593665.call(nil, query_593666, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_593650(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_593651, base: "/",
    url: url_GetUpdateStopwordOptions_593652, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_593702 = ref object of OpenApiRestCall_592364
proc url_PostUpdateSynonymOptions_593704(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateSynonymOptions_593703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593705 = query.getOrDefault("Action")
  valid_593705 = validateParameter(valid_593705, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_593705 != nil:
    section.add "Action", valid_593705
  var valid_593706 = query.getOrDefault("Version")
  valid_593706 = validateParameter(valid_593706, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593706 != nil:
    section.add "Version", valid_593706
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
  var valid_593707 = header.getOrDefault("X-Amz-Signature")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "X-Amz-Signature", valid_593707
  var valid_593708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593708 = validateParameter(valid_593708, JString, required = false,
                                 default = nil)
  if valid_593708 != nil:
    section.add "X-Amz-Content-Sha256", valid_593708
  var valid_593709 = header.getOrDefault("X-Amz-Date")
  valid_593709 = validateParameter(valid_593709, JString, required = false,
                                 default = nil)
  if valid_593709 != nil:
    section.add "X-Amz-Date", valid_593709
  var valid_593710 = header.getOrDefault("X-Amz-Credential")
  valid_593710 = validateParameter(valid_593710, JString, required = false,
                                 default = nil)
  if valid_593710 != nil:
    section.add "X-Amz-Credential", valid_593710
  var valid_593711 = header.getOrDefault("X-Amz-Security-Token")
  valid_593711 = validateParameter(valid_593711, JString, required = false,
                                 default = nil)
  if valid_593711 != nil:
    section.add "X-Amz-Security-Token", valid_593711
  var valid_593712 = header.getOrDefault("X-Amz-Algorithm")
  valid_593712 = validateParameter(valid_593712, JString, required = false,
                                 default = nil)
  if valid_593712 != nil:
    section.add "X-Amz-Algorithm", valid_593712
  var valid_593713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593713 = validateParameter(valid_593713, JString, required = false,
                                 default = nil)
  if valid_593713 != nil:
    section.add "X-Amz-SignedHeaders", valid_593713
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_593714 = formData.getOrDefault("DomainName")
  valid_593714 = validateParameter(valid_593714, JString, required = true,
                                 default = nil)
  if valid_593714 != nil:
    section.add "DomainName", valid_593714
  var valid_593715 = formData.getOrDefault("Synonyms")
  valid_593715 = validateParameter(valid_593715, JString, required = true,
                                 default = nil)
  if valid_593715 != nil:
    section.add "Synonyms", valid_593715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593716: Call_PostUpdateSynonymOptions_593702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_593716.validator(path, query, header, formData, body)
  let scheme = call_593716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593716.url(scheme.get, call_593716.host, call_593716.base,
                         call_593716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593716, url, valid)

proc call*(call_593717: Call_PostUpdateSynonymOptions_593702; DomainName: string;
          Synonyms: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Version: string (required)
  var query_593718 = newJObject()
  var formData_593719 = newJObject()
  add(formData_593719, "DomainName", newJString(DomainName))
  add(query_593718, "Action", newJString(Action))
  add(formData_593719, "Synonyms", newJString(Synonyms))
  add(query_593718, "Version", newJString(Version))
  result = call_593717.call(nil, query_593718, nil, formData_593719, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_593702(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_593703, base: "/",
    url: url_PostUpdateSynonymOptions_593704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_593685 = ref object of OpenApiRestCall_592364
proc url_GetUpdateSynonymOptions_593687(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateSynonymOptions_593686(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Synonyms` field"
  var valid_593688 = query.getOrDefault("Synonyms")
  valid_593688 = validateParameter(valid_593688, JString, required = true,
                                 default = nil)
  if valid_593688 != nil:
    section.add "Synonyms", valid_593688
  var valid_593689 = query.getOrDefault("DomainName")
  valid_593689 = validateParameter(valid_593689, JString, required = true,
                                 default = nil)
  if valid_593689 != nil:
    section.add "DomainName", valid_593689
  var valid_593690 = query.getOrDefault("Action")
  valid_593690 = validateParameter(valid_593690, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_593690 != nil:
    section.add "Action", valid_593690
  var valid_593691 = query.getOrDefault("Version")
  valid_593691 = validateParameter(valid_593691, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_593691 != nil:
    section.add "Version", valid_593691
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
  var valid_593692 = header.getOrDefault("X-Amz-Signature")
  valid_593692 = validateParameter(valid_593692, JString, required = false,
                                 default = nil)
  if valid_593692 != nil:
    section.add "X-Amz-Signature", valid_593692
  var valid_593693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593693 = validateParameter(valid_593693, JString, required = false,
                                 default = nil)
  if valid_593693 != nil:
    section.add "X-Amz-Content-Sha256", valid_593693
  var valid_593694 = header.getOrDefault("X-Amz-Date")
  valid_593694 = validateParameter(valid_593694, JString, required = false,
                                 default = nil)
  if valid_593694 != nil:
    section.add "X-Amz-Date", valid_593694
  var valid_593695 = header.getOrDefault("X-Amz-Credential")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Credential", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-Security-Token")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Security-Token", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-Algorithm")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Algorithm", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-SignedHeaders", valid_593698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593699: Call_GetUpdateSynonymOptions_593685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_593699.validator(path, query, header, formData, body)
  let scheme = call_593699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593699.url(scheme.get, call_593699.host, call_593699.base,
                         call_593699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593699, url, valid)

proc call*(call_593700: Call_GetUpdateSynonymOptions_593685; Synonyms: string;
          DomainName: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593701 = newJObject()
  add(query_593701, "Synonyms", newJString(Synonyms))
  add(query_593701, "DomainName", newJString(DomainName))
  add(query_593701, "Action", newJString(Action))
  add(query_593701, "Version", newJString(Version))
  result = call_593700.call(nil, query_593701, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_593685(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_593686, base: "/",
    url: url_GetUpdateSynonymOptions_593687, schemes: {Scheme.Https, Scheme.Http})
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
